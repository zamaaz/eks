variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "ap-south-1"
}

variable "cluster_name" {
  description = "A unique name for the EKS cluster."
  type        = string
  default     = "my-eks-cluster"
}

variable "k8s_version" {
  description = "The desired Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.29"
}

# --- Worker Node Configuration ---

variable "node_group_name" {
  description = "A unique name for the worker node group."
  type        = string
  default     = "my-eks-nodegroup"
}

variable "node_instance_type" {
  description = "The instance type for the worker nodes."
  type        = string
  default     = "t3.medium"
}

variable "node_min_size" {
  description = "The minimum number of nodes in the node group."
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "The maximum number of nodes in the node group."
  type        = number
  default     = 3
}

variable "node_desired_size" {
  description = "The desired number of nodes to start with."
  type        = number
  default     = 2
}

variable "key_name" {
  description = "The EC2 key pair name for SSH access to the worker nodes."
  type        = string
}

# --- Required Networking Inputs ---

variable "vpc_id" {
  description = "The ID of the VPC to deploy the EKS cluster into."
  type        = string
}

variable "public_subnet_ids" {
  description = "A list of public subnet IDs for the EKS control plane."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "A list of private subnet IDs for the worker nodes."
  type        = list(string)
}
