
# Module 02: Autoscaler Configuration

## Description

This module configures the Kubernetes Cluster Autoscaler for the EKS clusters created in the previous step. The Cluster Autoscaler adjusts the number of nodes in the cluster based on the workload.

### Main Files

- **main.tf**: Contains the main configuration for the autoscaler.
- **variables.tf**: Defines the input variables for the module.
- **output.tf**: Specifies the outputs of the module.

### Detailed Breakdown

#### main.tf

The `main.tf` file includes resources for the Cluster Autoscaler setup.

```hcl
resource "kubernetes_deployment" "cluster_autoscaler" {
  metadata {
    name      = "cluster-autoscaler"
    namespace = "kube-system"
    labels = {
      app = "cluster-autoscaler"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "cluster-autoscaler"
      }
    }

    template {
      metadata {
        labels = {
          app = "cluster-autoscaler"
        }
      }

      spec {
        container {
          name  = "cluster-autoscaler"
          image = "k8s.gcr.io/autoscaler/cluster-autoscaler:v1.20.0"

          command = [
            "./cluster-autoscaler",
            "--v=4",
            "--stderrthreshold=info",
            "--cloud-provider=aws",
            "--skip-nodes-with-local-storage=false",
            "--expander=least-waste",
            "--nodes=1:10:YOUR_NODE_GROUP_NAME"
          ]

          env {
            name  = "AWS_REGION"
            value = "us-west-2"
          }
        }
      }
    }
  }
}
```

- `metadata`: Sets metadata for the deployment including name and namespace.
- `spec`: Defines the specifications for the deployment, such as replicas, selectors, and template configurations.
- `container`: Configures the container for the Cluster Autoscaler, specifying the image and command.

#### variables.tf

Defines input variables used in the module.

```hcl
variable "min_size" {
  description = "Minimum number of nodes in the cluster"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of nodes in the cluster"
  type        = number
  default     = 10
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}
```

- `min_size`: Minimum number of nodes in the autoscaler group.
- `max_size`: Maximum number of nodes in the autoscaler group.
- `region`: AWS region for the autoscaler.

### Execution Steps

1. Configure variables in `variables.tf` or via command-line arguments.
2. Initialize Terraform with `terraform init`.
3. Apply the autoscaler configuration with `terraform apply`.

### Outputs

Key outputs include:

- `autoscaler_policy_id`: The ID of the autoscaler policy.
- `autoscaler_role_arn`: The ARN of the autoscaler role.

