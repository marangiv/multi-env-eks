resource "terraform_data" "generate_kubeconfig_and_diagnose" {
  input = {
    us_west_2_cluster_name = var.us_west_2_cluster_name
    us_west_2_endpoint     = var.us_west_2_endpoint
    us_west_2_cert_auth_data = var.us_west_2_cert_auth_data
    us_east_1_cluster_name = var.us_east_1_cluster_name
    us_east_1_endpoint     = var.us_east_1_endpoint
    us_east_1_cert_auth_data = var.us_east_1_cert_auth_data
    eu_west_1_cluster_name = var.eu_west_1_cluster_name
    eu_west_1_endpoint     = var.eu_west_1_endpoint
    eu_west_1_cert_auth_data = var.eu_west_1_cert_auth_data
  }

  triggers_replace = timestamp()

  provisioner "local-exec" {
    command = <<-EOT
      #!/bin/bash
      set -e

      mkdir -p kubectl_configs
      mkdir -p diagnostic_logs

      generate_kubeconfig() {
        local region=$1
        local cluster_name=$2
        local endpoint=$3
        local cert_auth_data=$4
        local config_file="kubectl_configs/kubeconfig-$region"

        cat << EOF > "$config_file"
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: $cert_auth_data
    server: $endpoint
  name: $cluster_name
contexts:
- context:
    cluster: $cluster_name
    user: $cluster_name
  name: $cluster_name
current-context: $cluster_name
kind: Config
preferences: {}
users:
- name: $cluster_name
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: aws
      args:
        - "eks"
        - "get-token"
        - "--cluster-name"
        - "$cluster_name"
        - "--region"
        - "$region"
EOF

        chmod 600 "$config_file"
        echo "Generated kubeconfig for $region"
      }

      generate_kubeconfig "us-west-2" "${self.input.us_west_2_cluster_name}" "${self.input.us_west_2_endpoint}" "${self.input.us_west_2_cert_auth_data}"
      generate_kubeconfig "us-east-1" "${self.input.us_east_1_cluster_name}" "${self.input.us_east_1_endpoint}" "${self.input.us_east_1_cert_auth_data}"
      generate_kubeconfig "eu-west-1" "${self.input.eu_west_1_cluster_name}" "${self.input.eu_west_1_endpoint}" "${self.input.eu_west_1_cert_auth_data}"

      if [ -f "./run_diagnostics.sh" ]; then
        chmod +x ./run_diagnostics.sh
        ./run_diagnostics.sh
      else
        echo "WARNING: run_diagnostics.sh not found. Skipping diagnostics."
      fi
    EOT
  }
}