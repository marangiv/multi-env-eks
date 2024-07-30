
# Module 04: ArgoCD Implementation

## Description

This module implements ArgoCD for managing application deployments on the EKS clusters. ArgoCD is a continuous delivery tool for Kubernetes that allows you to manage application deployments declaratively using GitOps principles.

### Main Files

- **main.tf**: Contains the main configuration for ArgoCD.
- **variables.tf**: Defines the input variables for the module.
- **outputs.tf**: Specifies the outputs of the module.

### Detailed Breakdown

#### main.tf

The `main.tf` file includes resources for deploying ArgoCD on the EKS cluster.

```hcl
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.argocd_namespace
  }
}

resource "kubernetes_deployment" "argocd_server" {
  metadata {
    name      = "argocd-server"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = {
      app = "argocd"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "argocd"
      }
    }

    template {
      metadata {
        labels = {
          app = "argocd"
        }
      }

      spec {
        container {
          name  = "argocd-server"
          image = "argoproj/argocd:v2.0.4"
          ports {
            container_port = 80
          }
        }
      }
    }
  }
}
```

- `kubernetes_namespace`: Creates a namespace for ArgoCD.
- `kubernetes_deployment`: Deploys the ArgoCD server within the created namespace.

#### variables.tf

Defines the variables used in the module.

```hcl
variable "argocd_namespace" {
  description = "The namespace where ArgoCD will be installed"
  type        = string
  default     = "argocd"
}
```

- `argocd_namespace`: Namespace for the ArgoCD installation.

### Execution Steps

1. Configure variables in `variables.tf` or via command-line arguments.
2. Initialize Terraform with `terraform init`.
3. Deploy ArgoCD with `terraform apply`.

### Outputs

Key outputs include:

- `argocd_server_url`: The URL of the ArgoCD server.
- `argocd_admin_password`: The admin password for ArgoCD.

