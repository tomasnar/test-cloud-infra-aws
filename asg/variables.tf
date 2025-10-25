variable "aws_region" {
  description = "The AWS region to create things in."
  default     = "ap-southeast-1"
}

variable "vpc_id" {
  description = "The VPC to create things in."
}

data "aws_subnets" "all" {
  vpc_id = var.vpc_id
}

# Amazon Linux latest (x64)
data "aws_ami" "amazonlinux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*gp2"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

variable "name" {
  description = "Name of test instance"
}

variable "instance_type" {
  default     = "t2.micro"
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
