#!/usr/bin/env bash

# generate_kubeconfig_env.sh
#
# This script generates kubeconfig files for multiple EKS clusters across different AWS regions.
# It retrieves cluster information from environment variables and creates a separate kubeconfig file for each cluster.
#
# Prerequisites:
#   - AWS CLI
#   - kubectl
#   - bash
#
# Required Environment Variables:
#   - US_WEST_2_CLUSTER_NAME, US_WEST_2_ENDPOINT, US_WEST_2_CERT_AUTH_DATA
#   - US_EAST_1_CLUSTER_NAME, US_EAST_1_ENDPOINT, US_EAST_1_CERT_AUTH_DATA
#   - EU_WEST_1_CLUSTER_NAME, EU_WEST_1_ENDPOINT, EU_WEST_1_CERT_AUTH_DATA
#
# Usage: bash ./generate_kubeconfig_env.sh
#
# The script doesn't accept any arguments. It expects the environment variables to be set before execution.

# Ensure the script is run with bash
if [ -z "$BASH_VERSION" ]; then
    echo "This script requires bash to run. Please use: bash $0" >&2
    exit 1
fi

# Exit the script if any command fails
set -e

# Function to log messages with timestamps
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >&2
}

# Function to log error messages and exit
error() {
    log "ERROR: $1"
    exit 1
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to generate kubeconfig for a region
generate_kubeconfig() {
    local region=$1
    local cluster_name=$2
    local endpoint=$3
    local cert_auth_data=$4

    log "Generating kubeconfig for ${region}"
    log "Cluster Name: ${cluster_name}"
    log "Endpoint: ${endpoint}"
    log "Cert Auth Data length: ${#cert_auth_data}"

    # Check if all required information is provided
    if [ -z "${cluster_name}" ] || [ -z "${endpoint}" ] || [ -z "${cert_auth_data}" ]; then
        error "Missing required information for ${region}"
    fi

    # Convert region format (e.g., US_WEST_2 to us-west-2)
    local aws_region=$(echo ${region} | tr '[:upper:]' '[:lower:]' | tr '_' '-')

    # Create kubeconfig file
    cat << EOF > ./kubeconfig-${aws_region}
apiVersion: v1
clusters:
- cluster:
    server: ${endpoint}
    certificate-authority-data: ${cert_auth_data}
  name: ${cluster_name}
contexts:
- context:
    cluster: ${cluster_name}
    user: ${cluster_name}
  name: ${cluster_name}
current-context: ${cluster_name}
kind: Config
preferences: {}
users:
- name: ${cluster_name}
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: aws
      args:
        - "eks"
        - "get-token"
        - "--cluster-name"
        - "${cluster_name}"
        - "--region"
        - "${aws_region}"
EOF

    log "Generated kubeconfig for ${region}"

    # Set file permissions
    chmod 600 ./kubeconfig-${aws_region} || error "Failed to set permissions for kubeconfig-${aws_region}"

    log "Modified permissions to 600 for kubeconfig for ${region}"

    # Verify AWS identity
    log "Verifying AWS identity..."
    aws sts get-caller-identity || error "Failed to verify AWS identity"

    # Test kubectl
    log "Testing kubectl connection..."
    kubectl --kubeconfig=./kubeconfig-${aws_region} get nodes || error "Failed to connect to cluster with kubectl"
}

# Function to clean up in case of errors
cleanup() {
    log "Cleaning up temporary files..."
    # Add cleanup actions here if needed
}

# Set up trap for cleanup on exit
trap cleanup EXIT

# Check for required commands
for cmd in aws kubectl; do
    command_exists $cmd || error "$cmd is required but not installed."
done

# Check if the script is run with arguments
if [ "$#" -ne 0 ]; then
    error "This script doesn't accept any arguments."
fi

# Check if the current directory is writable
if [ ! -w . ]; then
    error "Current directory is not writable. Cannot create kubeconfig files."
fi

# Main script execution
log "Starting kubeconfig generation process"

# List of regions
regions="US_WEST_2 US_EAST_1 EU_WEST_1"

# Generate kubeconfig for each region
for region in $regions; do
    cluster_name_var="${region}_CLUSTER_NAME"
    endpoint_var="${region}_ENDPOINT"
    cert_auth_data_var="${region}_CERT_AUTH_DATA"

    # Use eval to get the values of the variables
    cluster_name=$(eval echo \$$cluster_name_var)
    endpoint=$(eval echo \$$endpoint_var)
    cert_auth_data=$(eval echo \$$cert_auth_data_var)

    # Check if all required environment variables are set
    if [ -z "${cluster_name}" ] || [ -z "${endpoint}" ] || [ -z "${cert_auth_data}" ]; then
        error "Missing required environment variables for ${region}"
    fi

    log "${region}_CLUSTER_NAME: ${cluster_name}"
    log "${region}_ENDPOINT: ${endpoint}"
    log "${region}_CERT_AUTH_DATA length: ${#cert_auth_data}"

    # Generate kubeconfig for the region
    generate_kubeconfig "$region" "${cluster_name}" "${endpoint}" "${cert_auth_data}"
done

log "All kubeconfig files generated successfully!"