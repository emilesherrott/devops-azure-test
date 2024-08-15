terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.12"
    }
  }
  backend "s3" {
    bucket = "mybucket"       # Will be overridden from build
    key    = "path/to/my/key" # Will be overridden from build
    region = "us-east-1"
  }
}

resource "aws_default_vpc" "default" {

}

data "aws_subnets" "subnets" {
  filter {
    name = "vpc-id"
    values = [aws_default_vpc.default.id]
  }
}

module "lfacademy-cluster" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "lfacademy-cluster"
  cluster_version = "1.28"
  subnet_ids      = ["subnet-0565c72c8be2a4a50", "subnet-0e0be61b12e125be5"]
  vpc_id                         = aws_default_vpc.default.id
  cluster_endpoint_public_access = true
  eks_managed_node_groups = {
    default = {
      instance_types = ["t2.micro"]
      min_size       = 1
      max_size       = 10
      desired_size   = 3
    }
  }
}

# provider "kubernetes" {
  # host                   = data.aws_eks_cluster.cluster.endpoint
  # cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  # token                  = data.aws_eks_cluster_auth.cluster.token
# }



# data "aws_eks_cluster" "cluster" {
#   name = "lfacademy-cluster"
# }

# data "aws_eks_cluster_auth" "cluster" {
#   name = "lfacademy-cluster"
# }



# resource "kubernetes_cluster_role_binding" "example" {
#   metadata {
#     name = "fabric8-rbac"
#   }
#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "ClusterRole"
#     name      = "cluster-admin"
#   }
#   subject {
#     kind      = "ServiceAccount"
#     name      = "default"
#     namespace = "default"
#   }
# }


provider "aws" {
  region  = "us-east-1"
}