variable "aws_region" {
  description = "The AWS region to create things in."
  default     = "ap-southeast-1"
}

variable "vpc_id" {
  description = "The VPC to create things in."
}

data "aws_subnets" "all" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

# Amazon Linux latest (x64)
data "aws_ami" "amazonlinux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    # Matches the standard, non-minimal, x86_64 AMI. 
    # Use 'al2023-ami-minimal-2023.*-x86_64' for the minimal version.
    values = ["al2023-ami-2023.*-x86_64"] 
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

variable "name" {
  description = "Name of test instance"
}

variable "instance_type" {
  default     = "t3.micro"
  description = "AWS instance type"
}

variable "asg_min" {
  description = "Min numbers of servers in ASG"
  default     = "1"
}

variable "asg_max" {
  description = "Max numbers of servers in ASG"
  default     = "1"
}

variable "asg_desired" {
  description = "Desired numbers of servers in ASG"
  default     = "1"
}
