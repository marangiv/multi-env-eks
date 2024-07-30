#!/bin/bash

set -e

# Function to run and log kubectl commands
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
regions=("us-west-2" "us-east-1" "eu-west-1")

for region in "${regions[@]}"; do
    if [ -f "kubectl_configs/kubeconfig-$region" ]; then
        run_diagnostics "$region"
    else
        echo "Kubeconfig not found for $region. Skipping diagnostics."
    fi
done

echo "All diagnostics completed. Check diagnostic_logs directory for results."