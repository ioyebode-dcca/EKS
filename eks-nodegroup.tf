eks_managed_node_groups = {
  default = {
    desired_size = 1
    min_size     = 1
    max_size     = 2
    instance_types = ["t3.small"] 
  }
}