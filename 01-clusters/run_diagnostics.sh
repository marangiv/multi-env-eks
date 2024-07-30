#!/bin/bash
set +e

# This Bash script is designed to run diagnostic commands using kubectl 
# for multiple AWS EKS clusters and log the results. 
# It iterates over a list of specified regions, 
# runs a series of kubectl commands for each region, and stores the results in log files.

# Function to run and log kubectl commands
# Runs a specified kubectl command for a given region.
# Logs the command and its output to a log file (log_file) specific to the region.

# Parameters:
# region: The AWS region of the EKS cluster.
# command: The kubectl command to run.
# log_file: The log file where the output will be stored.

run_kubectl_command() {
    local region=$1
    local command=$2
    local log_file="diagnostic_logs/${region}_diagnostics.log"
    
    echo "Running command for $region: $command"
    echo "Command: $command" >> "$log_file"
    if KUBECONFIG="kubectl_configs/kubeconfig-$region" kubectl $command >> "$log_file" 2>&1; then
        echo "Command succeeded" >> "$log_file"
    else
        echo "Command failed: $command" >> "$log_file"
    fi
    echo "" >> "$log_file"
}

# Function to run diagnostics for a region
# Runs a series of predefined kubectl commands for a given region.
# Utilizes the run_kubectl_command function to execute and log each command.
# Parameter: 
# region, The AWS region of the EKS cluster.
run_diagnostics() {
    local region=$1
    
    echo "Running diagnostics for $region"
    
    # List of commands to run
    commands=(
        "get nodes -o wide"
        "get namespaces"
        "get pods --all-namespaces"
        "get services --all-namespaces"
        "get deployments --all-namespaces"
        "describe nodes"
        "top nodes"
        "top pods --all-namespaces"
        "get events --all-namespaces --sort-by=.metadata.creationTimestamp"
    )
    
    for cmd in "${commands[@]}"; do
        run_kubectl_command "$region" "$cmd"
    done
    
    echo "Diagnostics completed for $region"
    echo
}

# Main execution
# Iterates over a list of regions.
regions=("us-west-2" "us-east-1" "eu-west-1")

# Iterates over each region.
# Checks if the kubeconfig file for the region exists.
# If the kubeconfig file exists, it runs diagnostics for that region.
# If the kubeconfig file does not exist, it skips the diagnostics for that region.

for region in "${regions[@]}"; do
    if [ -f "kubectl_configs/kubeconfig-$region" ]; then
        run_diagnostics "$region"
    else
        echo "Kubeconfig not found for $region. Skipping diagnostics."
    fi
done

echo "All diagnostics completed. Check diagnostic_logs directory for results."