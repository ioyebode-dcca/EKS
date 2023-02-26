# Define the variables
variable "region" {
  type = string
  default = "us-west-2"
}

variable "worker_instance_type" {
  type = string
  default = "t2.micro"
}

variable "num_workers" {
  type = number
  default = 3
}

variable "cluster_name" {
  type = string
  default = "my-kubernetes-cluster"
}

variable "subnet_id_1" {
  type = string
  default = "subnet-06d634c2ec29a61ac"
 }
 
 variable "subnet_id_2" {
  type = string
  default = "subnet-0fcac7bf0f5271fc5"
 }
