#################################################
## Terraform code for CLO835 assignment 2  ######
## Maintainer - Rajat Garg   ####################
#################################################

#  Define the provider
provider "aws" {
  region = "us-east-1"
}

# Data source for AMI id
data "aws_ami" "latest_amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}


# Data source for availability zones in us-east-1
data "aws_availability_zones" "available" {
  state = "available"
}

# Data block to retrieve the default VPC id
data "aws_vpc" "default" {
  default = true
}

# Data block to retrieve the IAM instance profile
data "aws_iam_instance_profile" "instance_profile" {
  name = "LabInstanceProfile"
}

# Define tags locally
locals {
  default_tags = {
    "Owner"   = "Rajat"
    "App"     = "K8s-app"
    "Project" = "CLO835-Assignment2"
  }
}

# Adding SSH key to Amazon EC2
resource "aws_key_pair" "my_key" {
  key_name   = "linuxkey"
  public_key = file("~/.ssh/rajat.pub")
}

# Provision EC2 instance 
resource "aws_instance" "my_amazon" {
  ami                         = data.aws_ami.latest_amazon_linux.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.my_key.key_name
  vpc_security_group_ids      = [aws_security_group.my_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = data.aws_iam_instance_profile.instance_profile.name
  user_data                   = "${file("install_packages.sh")}"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.default_tags,
    {
      "Name" = "K8s-Server"
    }
  )
}


# Security Group
resource "aws_security_group" "my_sg" {
  name        = "web_sg"
  description = "Allow http inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description      = "http 8080 from everywhere"
    from_port        = 30000
    to_port          = 30000
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "http 8081 from everywhere"
    from_port        = 30001
    to_port          = 30001
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
  ingress {
    description      = "SSH from Cloud9"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["${var.my_private_ip}/32", "${var.my_public_ip}/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(local.default_tags,
    {
      "Name" = "K8s-server-sg"
    }
  )
}

# Create Cats ECR repository
resource "aws_ecr_repository" "cats_repo" {
  name                 = "cats_repo"
  
  image_scanning_configuration {
    scan_on_push = true
  }
  
  tags = merge(local.default_tags,
    {
      "Name" = "cats_repo"
    }
  )
}

# Create Dogs ECR repository
resource "aws_ecr_repository" "dogs_repo" {
  name                 = "dogs_repo"
  
  image_scanning_configuration {
    scan_on_push = true
  }
  
  tags = merge(local.default_tags,
    {
      "Name" = "dogs_repo"
    }
  )
}