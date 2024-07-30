
# Module 03: IAM Configuration

## Description

This module configures the necessary IAM roles and policies for the EKS clusters and the autoscaler. These IAM roles and policies ensure that the EKS cluster and its components have the required permissions to function correctly.

### Main Files

- **main.tf**: Contains the main configuration for IAM resources.
- **variables.tf**: Defines the input variables for the module.
- **output.tf**: Specifies the outputs of the module.

### Detailed Breakdown

#### main.tf

The `main.tf` file includes IAM roles and policies.

```hcl
resource "aws_iam_role" "eks_cluster_role" {
  name = var.iam_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}
```

- `aws_iam_role`: Defines an IAM role with an assume role policy for EKS.
- `aws_iam_role_policy_attachment`: Attaches the AmazonEKSClusterPolicy to the IAM role.

#### variables.tf

Defines the variables used in the module.

```hcl
variable "iam_role_name" {
  description = "The name of the IAM role"
  type        = string
  default     = "eks-cluster-role"
}
```

- `iam_role_name`: Name of the IAM role, with a default value.

### Execution Steps

1. Configure variables in `variables.tf` or via command-line arguments.
2. Initialize Terraform with `terraform init`.
3. Create the IAM resources with `terraform apply`.

### Outputs

The main outputs include:

- `iam_role_arn`: The ARN of the created IAM role.
- `iam_policy_id`: The ID of the created IAM policy.

