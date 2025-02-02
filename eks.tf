provider "aws" {
  region = "us-east-1" # Replace with your desired AWS region
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "17.5.0"

  cluster_name    = "eks-cluster"
  cluster_version = "1.31"
  subnets         = aws_subnet.eks_subnet.*.id # Use the IDs of the subnets created above
  vpc_id          = aws_vpc.eks_vpc.id # Use the ID of the VPC created above

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }

  worker_groups_launch_template = [
    {
      name                 = "eks-worker-group"
      instance_type       = "t2.small"
      asg_desired_capacity = 2
      additional_security_group_ids = [aws_security_group.eks_sg.id] # Use the ID of the security group created above
      subnets             = aws_subnet.eks_subnet.*.id # Use the IDs of the subnets created above
      tags = {
        Terraform   = "true"
        Environment = "dev"
      }
    }
  ]
}

output "kubeconfig" {
  value = module.eks.kubeconfig
}
