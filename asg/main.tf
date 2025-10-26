terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "allaz" {}

module "nlb" {
  source = "terraform-aws-modules/alb/aws"

  name = "${var.name}-lb"

  load_balancer_type               = "network"
  vpc_id                           = var.vpc_id

  subnets            = data.aws_subnets.all.ids

  # Security Group
  security_group_ingress_rules = {
    web_rule = {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "WEB traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

#  access_logs = {
#    bucket = module.log_bucket.s3_bucket_id
#  }

  listeners = {
    ex-one = {
      port     = 80
      protocol = "TCP"
      forward = {
        target_group_key = "ex-target-one"
      }
    }
  }
  target_groups = {
    ex-target-one = {
      name_prefix            = "web-"
      protocol               = "TCP"
      port                   = 80
      connection_termination = true
      preserve_client_ip     = true
      create_attachment      = false
    }
  }
}

resource "aws_autoscaling_group" "web-asg" {
  vpc_zone_identifier = data.aws_subnets.all.ids
  name                = "${var.name}-asg"
  max_size            = var.asg_max
  min_size            = var.asg_min
  desired_capacity    = var.asg_desired
  force_delete        = true
  launch_template {
    id      = aws_launch_template.launch_template.id
    version = "$Latest"
  }

  target_group_arns = [
    module.nlb.target_groups["ex-target-one"].arn
  ]

  tag {
    key                 = "Name"
    value               = var.name
    propagate_at_launch = "true"
  }
}

resource "aws_autoscaling_schedule" "asg-turnoff" {
  scheduled_action_name  = "asg-turnoff"
  min_size               = 0
  max_size               = 0
  desired_capacity       = 0
  recurrence             = "0 18 * * *"
  autoscaling_group_name = aws_autoscaling_group.web-asg.name
}

resource "aws_launch_template" "launch_template" {
  name          = "${var.name}-template"
  image_id      = data.aws_ami.amazonlinux.image_id
  instance_type = var.instance_type
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }
  # Security group
  vpc_security_group_ids = [module.nlb.security_group_id]
  user_data              = filebase64("${path.module}/userdata.sh")
}

resource "aws_iam_role" "ec2_iam_role" {
  name = "${var.name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_iam_role_attachment" {
  for_each   = toset(local.ec2_instance_roles)
  role       = aws_iam_role.ec2_iam_role.name
  policy_arn = each.key
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.name}-instance-profile"
  role = aws_iam_role.ec2_iam_role.name
}
