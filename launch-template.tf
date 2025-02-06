resource "aws_launch_template" "eks_node_group" {
  name = "eks-node-group-launch-template"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 20
      volume_type = "gp3"
    }
  }

  network_interfaces {
    associate_public_ip_address = false
  }

  # Add tags to launched instances
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "EKS-managed-node"
    }
  }

  tags = {
    "kubernetes.io/cluster/${module.eks.cluster_name}" = "owned"
  }

  lifecycle {
    create_before_destroy = true
  }
}