# Tell Terraform to use AWS
provider "aws" {
  region = "us-east-1"  # Change this if you want a different region
}

# Create a VPC (virtual network)
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "demowebapi-vpc"
  cidr = "10.0.0.0/16"  # A range of IP addresses for our network

  azs             = ["us-east-1a", "us-east-1b"]  # Availability zones
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true  # Allows private subnets to access the internet
  single_nat_gateway = true  # Saves cost by using one NAT gateway
}

# Create an EKS cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "demowebapi-cluster"
  cluster_version = "1.27"  # Kubernetes version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      instance_types = ["t3.medium"]  # Type of virtual machines
    }
  }
}

# Tell Terraform to use Helm with our cluster
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
      command     = "aws"
    }
  }
}

# Deploy the Helm chart
resource "helm_release" "demowebapi" {
  name       = "demowebapi"
  chart      = "../helm/demowebapi"  # Path to your Helm chart
  namespace  = "default"

  set {
    name  = "image.repository"
    value = "259178953954.dkr.ecr.us-east-1.amazonaws.com/demowebapi"
  }
  set {
    name  = "image.tag"
    value = "latest"
  }
}