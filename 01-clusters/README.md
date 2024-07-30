
# 01-Setup-Cluster: Multi-Region EKS Cluster Deployment

This module sets up a multi-region Amazon EKS cluster environment using Terraform. It includes the creation of Virtual Private Clouds (VPCs) and EKS clusters across multiple AWS regions.

## Key Components

### Terraform and Provider Versions

This module specifies the required Terraform and provider versions to ensure compatibility and stability.

### AWS Providers

Defines AWS providers for each region to manage resources in specific AWS regions.

### Local Cluster Names

Creates a map of cluster names for each region based on the provided environment.

### VPC and EKS Clusters

Creates VPCs and EKS clusters in the specified AWS regions with appropriate configurations.

## Files and Configuration

### main.tf

This file contains the main Terraform configuration for setting up VPCs and EKS clusters.

```hcl
# This file defines the multi-region EKS cluster deployment

# Specify the required Terraform and provider versions
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Define AWS provider for each region
provider "aws" {
  alias  = "us-west-2"
  region = "us-west-2"
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "eu-west-1"
  region = "eu-west-1"
}

# Create a map of cluster names for each region
locals {
  cluster_names = {
    for region in var.regions :
    region => "eks-${var.environment}-${region}"
  }
}

module "vpc_us_east_1" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "vpc-${var.environment}-us-east-1"
  cidr = "10.1.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  public_subnets  = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Environment = var.environment
    Region      = "us-east-1"
  }

  providers = {
    aws = aws.us-east-1
  }
}

module "eks_us_east_1" {
  source = "../modules/eks"

  cluster_name    = local.cluster_names["us-east-1"]
  cluster_version = var.cluster_version
  vpc_id          = module.vpc_us_east_1.vpc_id
  private_subnets = module.vpc_us_east_1.private_subnets

  environment = var.environment
  region      = "us-east-1"

  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access

  cluster_addons = var.cluster_addons

  providers = {
    aws = aws.us-east-1
  }
}




# Create VPC and EKS cluster for us-west-2 region
module "vpc_us_west_2" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "vpc-${var.environment}-us-west-2"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Environment = var.environment
    Region      = "us-west-2"
  }

  providers = {
    aws = aws.us-west-2
  }
}

module "eks_us_west_2" {
  source = "../modules/eks"

  cluster_name    = local.cluster_names["us-west-2"]
  cluster_version = var.cluster_version
  vpc_id          = module.vpc_us_west_2.vpc_id
  private_subnets = module.vpc_us_west_2.private_subnets

  environment = var.environment
  region      = "us-west-2"

  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access

  cluster_addons = var.cluster_addons

  providers = {
    aws = aws.us-west-2
  }
}

module "vpc_eu_west_1" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "vpc-${var.environment}-eu-west-1"
  cidr = "10.2.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  private_subnets = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
  public_subnets  = ["10.2.101.0/24", "10.2.102.0/24", "10.2.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Environment = var.environment
    Region      = "eu-west-1"
  }

  providers = {
    aws = aws.eu-west-1
  }
}

module "eks_eu_west_1" {
  source = "../modules/eks"

  cluster_name    = local.cluster_names["eu-west-1"]
  cluster_version = var.cluster_version
  vpc_id          = module.vpc_eu_west_1.vpc_id
  private_subnets = module.vpc_eu_west_1.private_subnets

  environment = var.environment
  region      = "eu-west-1"

  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access

  cluster_addons = var.cluster_addons

  providers = {
    aws = aws.eu-west-1
  }
}

# Repeat the above pattern for us-east-1 and eu-west-1 regions
# (Code for other regions omitted for brevity)

# Output the cluster endpoints for each region
output "cluster_endpoints" {
  description = "Map of cluster endpoints"
  value = {
    us-west-2 = module.eks_us_west_2.cluster_endpoint
    us-east-1 = module.eks_us_east_1.cluster_endpoint
    eu-west-1 = module.eks_eu_west_1.cluster_endpoint
  }
}

# Output the VPC IDs for each region
output "vpc_ids" {
  description = "Map of VPC IDs"
  value = {
    us-west-2 = module.vpc_us_west_2.vpc_id
    us-east-1 = module.vpc_us_east_1.vpc_id
    eu-west-1 = module.vpc_eu_west_1.vpc_id
  }
}

# Output the kubectl configurations for each cluster
output "kubectl_configs" {
  description = "kubectl configs for each cluster"
  value = {
    us-west-2 = module.eks_us_west_2.kubectl_config
    us-east-1 = module.eks_us_east_1.kubectl_config
    eu-west-1 = module.eks_eu_west_1.kubectl_config
  }
  sensitive = true
}
```

### variables.tf

Defines the input variables for the module, including environment, regions, cluster version, endpoint access settings, and cluster addons.

```hcl
# This file defines the input variables for the root module

variable "environment" {
  description = "Environment name, e.g. 'dev', 'staging', 'prod'"
  type        = string
}

variable "regions" {
  description = "List of AWS regions to deploy to"
  type        = list(string)
  default     = ["us-west-2", "us-east-1", "eu-west-1"]
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS clusters"
  type        = string
  default     = "1.30"
}

variable "cluster_endpoint_private_access" {
  description = "Whether the Amazon EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Whether the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = false
}

variable "cluster_addons" {
  description = "Map of cluster addon configurations to enable for the clusters"
  type        = any
  default     = {}
}
```

### kubeconfig.tf

Defines the Terraform configuration for generating kubeconfig files for each EKS cluster.

```hcl
resource "null_resource" "generate_kubeconfig" {
  depends_on = [
    module.eks_us_west_2,
    module.eks_us_east_1,
    module.eks_eu_west_1
  ]

  provisioner "local-exec" {
    command = <<-EOT
      export US_WEST_2_CLUSTER_NAME="${module.eks_us_west_2.cluster_name}"
      export US_WEST_2_ENDPOINT="${module.eks_us_west_2.cluster_endpoint}"
      export US_WEST_2_CERT_AUTH_DATA="${module.eks_us_west_2.cluster_certificate_authority_data}"
      export US_EAST_1_CLUSTER_NAME="${module.eks_us_east_1.cluster_name}"
      export US_EAST_1_ENDPOINT="${module.eks_us_east_1.cluster_endpoint}"
      export US_EAST_1_CERT_AUTH_DATA="${module.eks_us_east_1.cluster_certificate_authority_data}"
      export EU_WEST_1_CLUSTER_NAME="${module.eks_eu_west_1.cluster_name}"
      export EU_WEST_1_ENDPOINT="${module.eks_eu_west_1.cluster_endpoint}"
      export EU_WEST_1_CERT_AUTH_DATA="${module.eks_eu_west_1.cluster_certificate_authority_data}"
      bash ./generate_kubeconfig.sh
    EOT
  }

  triggers = {
    always_run = "${timestamp()}"
  }
}
```

### output.tf

Defines the output variables for the module, including cluster endpoints, VPC IDs, and kubectl configurations.

```hcl
output "cluster_names" {
  description = "Names of the EKS clusters"
  value = {
    us_west_2 = module.eks_us_west_2.cluster_name
    us_east_1 = module.eks_us_east_1.cluster_name
    eu_west_1 = module.eks_eu_west_1.cluster_name
  }
}

output "cluster_endpoints" {
  description = "Endpoints for the EKS clusters"
  value = {
    us_west_2 = module.eks_us_west_2.cluster_endpoint
    us_east_1 = module.eks_us_east_1.cluster_endpoint
    eu_west_1 = module.eks_eu_west_1.cluster_endpoint
  }
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the clusters"
  value = {
    us_west_2 = module.eks_us_west_2.cluster_certificate_authority_data
    us_east_1 = module.eks_us_east_1.cluster_certificate_authority_data
    eu_west_1 = module.eks_eu_west_1.cluster_certificate_authority_data
  }
}

# Output the VPC IDs for each region
output "vpc_ids" {
  description = "Map of VPC IDs"
  value = {
    us-west-2 = module.vpc_us_west_2.vpc_id
    us-east-1 = module.vpc_us_east_1.vpc_id
    eu-west-1 = module.vpc_eu_west_1.vpc_id
  }
}

# Output the kubectl configurations for each cluster
output "kubectl_configs" {
  description = "kubectl configs for each cluster"
  value = {
    us-west-2 = module.eks_us_west_2.kubectl_config
    us-east-1 = module.eks_us_east_1.kubectl_config
    eu-west-1 = module.eks_eu_west_1.kubectl_config
  }
  sensitive = true
}
```

### generate_kubeconfig.sh

A script to generate kubeconfig files for each region based on the output of the Terraform configuration.

```bash
#!/bin/bash

# Funzione per generare kubeconfig per una regione
generate_kubeconfig() {
    local region=$1
    local cluster_name=$2
    local endpoint=$3
    local cert_auth_data=$4

    kubectl config set-cluster "${cluster_name}" \
        --server="${endpoint}" \
        --certificate-authority=<(echo "${cert_auth_data}" | base64 --decode) \
        --kubeconfig="./kubeconfig-${region}"

    kubectl config set-context "${cluster_name}" \
        --cluster="${cluster_name}" \
        --user="${cluster_name}" \
        --kubeconfig="./kubeconfig-${region}"

    kubectl config use-context "${cluster_name}" --kubeconfig="./kubeconfig-${region}"

    aws eks get-token --cluster-name "${cluster_name}" --region "${region}" \
        | kubectl apply -f - --kubeconfig="./kubeconfig-${region}"

    echo "Generated kubeconfig for ${region}"
}

# Genera kubeconfig per ogni regione
generate_kubeconfig "us-west-2" "${US_WEST_2_CLUSTER_NAME}" "${US_WEST_2_ENDPOINT}" "${US_WEST_2_CERT_AUTH_DATA}"
generate_kubeconfig "us-east-1" "${US_EAST_1_CLUSTER_NAME}" "${US_EAST_1_ENDPOINT}" "${US_EAST_1_CERT_AUTH_DATA}"
generate_kubeconfig "eu-west-1" "${EU_WEST_1_CLUSTER_NAME}" "${EU_WEST_1_ENDPOINT}" "${EU_WEST_1_CERT_AUTH_DATA}"

echo "All kubeconfig files generated successfully!"
```

## Detailed Steps

### Step 1: Define IAM Roles

The module defines IAM roles required for the EKS clusters. These roles are used by the nodes, Fargate profiles, and service accounts to interact with AWS services securely.

1. **Node IAM Role**: This role is assigned to the worker nodes in the EKS cluster. It includes policies that allow nodes to register with the cluster and interact with other AWS services such as CloudWatch and ECR.

2. **Fargate Profile IAM Role**: This role is assigned to the Fargate profiles in the EKS cluster. It includes policies that allow Fargate tasks to interact with AWS services securely.

3. **Service Account IAM Role**: This role is associated with Kubernetes service accounts. It provides fine-grained permissions to specific Kubernetes pods, allowing them to interact with AWS services securely.

### Step 2: Attach Policies

The module attaches necessary policies to each IAM role defined in the previous step. These policies include:

- **AmazonEKSWorkerNodePolicy**: Allows worker nodes to interact with the EKS cluster.
- **AmazonEKS_CNI_Policy**: Allows the VPC CNI plugin to manage network interfaces in the VPC.
- **AmazonEC2ContainerRegistryReadOnly**: Allows nodes to pull images from Amazon ECR.
- **CloudWatchAgentServerPolicy**: Allows nodes to publish metrics to CloudWatch.

### Step 3: Output IAM Role ARNs

The module outputs the ARNs of the IAM roles created. These ARNs are used in the EKS cluster setup to associate the correct IAM roles with the cluster resources.

### Step 4: Generate Kubeconfig Files

The module uses a script `generate_kubeconfig.sh` to automatically generate kubeconfig files for each region after the EKS clusters are created. This script uses the output variables from Terraform to configure kubectl access.

## Architectural Choices

1. **Multi-Region Deployment**: Deploying clusters across multiple AWS regions ensures high availability and disaster recovery. If one region experiences an outage, clusters in other regions can continue to operate.

2. **VPC Configuration**: Separate VPCs are created for each region to ensure network isolation and to control network configurations independently. Each VPC includes private and public subnets, with a NAT gateway for secure internet access.

3. **EKS Clusters**: Amazon EKS is chosen for its managed Kubernetes service, which simplifies cluster management and integrates seamlessly with other AWS services. The module creates EKS clusters in each specified region.

4. **Helm for Package Management**: Helm charts are used for deploying and managing Kubernetes applications, ensuring reproducible deployments and ease of updates.

5. **Security**: 
   - **IAM Policies**: Defined roles and policies to follow the principle of least privilege.
   - **Endpoint Access**: Configurations to manage public and private access to the cluster endpoints.
   - **Certificates**: Certificates are managed to ensure secure communication within and between clusters.

## Accessing the Application

1. **Kubeconfig**: Use the kubeconfig files provided (`kubeconfig-us-west-2`, `kubeconfig-us-east-1`, `kubeconfig-eu-west-1`) to access the clusters. Example:
   ```sh
   export KUBECONFIG=./kubeconfig-us-west-2
   kubectl get nodes
   ```

2. **Helm Charts**: Deploy applications using Helm charts. Example:
   ```sh
   helm install my-app ./charts/my-app
   ```

3. **Dashboard**: Access the Kubernetes dashboard by setting up port forwarding:
   ```sh
   kubectl proxy
   ```
   Then open [http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/](http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/) in your browser.

## TODO Security Enhancements

1. **Secrets Management**: Use AWS Secrets Manager or HashiCorp Vault to securely store sensitive information like tokens and configuration secrets.
2. **IAM Policies**: Regularly review and minimize IAM policies to ensure they follow the principle of least privilege.
3. **Encryption**: Ensure all data at rest and in transit is encrypted using AWS KMS and TLS/SSL.
4. **Audit Logs**: Enable and monitor audit logs for all clusters to detect and respond to unauthorized activities.

## TODO Execution of Scripts

1. **Automation**: Use CI/CD pipelines to automate the deployment and modification of IAM roles and policies, ensuring consistency and reducing manual errors.
2. **Validation**: Implement pre-deployment validations and post-deployment checks to ensure the integrity and correctness of the IAM configurations.

## TODO Testing (Unit and Integration)

1. **Unit Tests**: Write unit tests for IAM configurations using tools like Terratest to validate individual IAM roles and policies.
2. **Integration Tests**: Implement integration tests to validate the entire IAM setup end-to-end using AWS IAM tools and scripts.
3. **Continuous Testing**: Integrate tests into the CI/CD pipeline to ensure that every change is validated before deployment.

## TODO General Improvements

1. **Documentation**: Maintain comprehensive documentation for the IAM roles and policies, including descriptions of each role and policy.
2. **Modularization**: Ensure that the IAM configurations are modularized for reusability and maintainability.
3. **Security Audits**: Regularly conduct security audits of IAM roles and policies to ensure compliance with best practices.
                                                                                                                                                                    

## Credits and Acknowledgements

This IAM configuration module is inspired by best practices and guidelines provided by AWS for securing EKS clusters.

## Conclusion

This module provides a secure, robust, and efficient IAM setup for managing permissions and roles required by EKS clusters deployed across multiple AWS regions.
