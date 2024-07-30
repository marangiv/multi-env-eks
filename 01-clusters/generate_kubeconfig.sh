#!/bin/bash

# generate_kubeconfig.sh
#
# This script generates kubeconfig files for multiple EKS clusters across different AWS regions.
# It retrieves cluster information from Terraform outputs and creates a separate kubeconfig file for each cluster.
#
# Prerequisites:
#   - Terraform CLI
#   - AWS CLI
#   - kubectl
#   - jq
#
# Usage: ./generate_kubeconfig.sh
#
# The script doesn't accept any arguments. It expects to be run in the same directory as the Terraform configuration.

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

# Function to extract a specific value from Terraform output
get_terraform_output() {
    local output_name=$1
    local region=$2
    local result

    result=$(terraform output -json $output_name 2>&1) || error "Failed to get Terraform output: $result"
    echo $result | jq -r ".$region" || error "Failed to parse Terraform output with jq"
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

    # Convert region format (e.g., us_west_2 to us-west-2)
    local aws_region=$(echo ${region} | tr '_' '-')

    # Create kubeconfig file
    cat << EOF > ./kubeconfig-${region}
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
    chmod 600 ./kubeconfig-${region} || error "Failed to set permissions for kubeconfig-${region}"

    log "Modified permissions to 600 for kubeconfig for ${region}"

    # Verify AWS identity
    log "Verifying AWS identity..."
    aws sts get-caller-identity || error "Failed to verify AWS identity"

    # Test kubectl
    log "Testing kubectl connection..."
    kubectl --kubeconfig=./kubeconfig-${region} get nodes || error "Failed to connect to cluster with kubectl"
}

# Function to clean up in case of errors
cleanup() {
    log "Cleaning up temporary files..."
    # Add cleanup actions here if needed
}

# Set up trap for cleanup on exit
trap cleanup EXIT

# Check for required commands
for cmd in terraform jq aws kubectl; do
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

log "Retrieving cluster information from Terraform state..."

# Array of regions
regions=("us_west_2" "us_east_1" "eu_west_1")

# Retrieve and store cluster information for each region
for region in "${regions[@]}"; do
    upper_region=$(echo $region | tr '[:lower:]' '[:upper:]' | tr '-' '_')
    
    cluster_name=$(get_terraform_output cluster_names $region)
    endpoint=$(get_terraform_output cluster_endpoints $region)
    cert_auth_data=$(get_terraform_output cluster_certificate_authority_data $region)

    log "${upper_region}_CLUSTER_NAME: ${cluster_name}"
    log "${upper_region}_ENDPOINT: ${endpoint}"
    log "${upper_region}_CERT_AUTH_DATA length: ${#cert_auth_data}"

    # Generate kubeconfig for the region
    generate_kubeconfig $region "$cluster_name" "$endpoint" "$cert_auth_data"
done

log "All kubeconfig files generated successfully!"