terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "allaz" {}

resource "aws_key_pair" "keypair" {
  key_name   = "${var.name}-keypair"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAgEAmn0Fz/9Y50QobhLnOP1Y5Sa+FtyUutH9X8wK+o7vfgEKN6KUO4MfleNvZZuIT2iy2EJLSUgBDz8ck1c7tJkC/zzLZyv/Y8T8SI1G3DyMTOPPwFd6Al9shN0Lc1Sh/BFricY7RjoUV8bjQTev9t4zaUFu/+AS/o/ZardNHKgavGW9e3sMnMLweTDPWSwT8EUPFZLdapPXvV3kbF8j4P9cAjLFhxlKy1COe+RkivjcdzlG9gVWq8yvlrSFyUTl40BCYlWbEdRhBhR8ppnP/T3KXOfkH6PJ8P2GLTpTiZhrTD/X4CxzkkNsVoEUllFGU8LXcKI+TdLPEGjMbUPr7Jr0x1Y4IZ4qzzHW3uZ1i6LedJgLtKyJla0v+rGYbR9vvvjYfln3KDazNLUnS82B/ONboADjK3Ts7br/E2+kJQ7GhrJnxQbywdh2ftcQz4SaWNiq/Zb5TiJxjDdizJf7j59kDUHB+fCOGSEF2y5rLBNsh86mbZLIwfyNuXQHS89yStV/qgcize3DviMJbNr2i2EkseLyV8upcD6+UtLoa5ZcqsYLZCQf6FuufBusoFmX+RO5EazZqVVrRcaoxwzCVM9+a2FcdW8LX4B8Il0DHScuexRSQUxMMRw+w6SYfDhA1SXol0dE7RF5zqk+vPqLfSNyZu8pcop/lWhiHFJP07WFVu0= rsa-key-20210730"
}

resource "aws_elb" "web-elb" {
  name = "${var.name}-elb"

  # The same availability zone as our instances
  subnets         = data.aws_subnets.all.ids
  security_groups = [aws_security_group.default.id]
  listener {
    instance_port     = 22
    instance_protocol = "tcp"
    lb_port           = 22
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:22"
    interval            = 30
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

  load_balancers = [aws_elb.web-elb.name]

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

  # Security group
  vpc_security_group_ids = [aws_security_group.default.id]
  user_data              = filebase64("${path.module}/userdata.sh")
  key_name               = aws_key_pair.keypair.key_name
}

# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "default" {
  name        = "${var.name}_sg"
  vpc_id      = var.vpc_id
  description = "Used in the terraform"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
