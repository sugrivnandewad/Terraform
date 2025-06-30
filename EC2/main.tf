provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
    bucket = "terraform-sbn"
    key    = "dev/ec2/terraform.tfstate"
    region = "ap-south-1" # Hardcoded region
  }

}

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "terraform-sbn"
    key    = "dev/network/terraform.tfstate"
    region = "ap-south-1" # Hardcoded region
  }

}
data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}


resource "aws_instance" "dev_instance" {
  ami                         = data.aws_ami.latest_amazon_linux.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.my_key_pair.key_name
  subnet_id                   = data.terraform_remote_state.network.outputs.public_subnet_ids[0] # Use the first public subnet ID
  iam_instance_profile        = "SSM"                                                            # Ensure this profile exists in your AWS account
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.dev_instance_sg.id]
  tags = {
    Name        = "DevInstance"
    Owner       = "DevTeam"
    Environment = "Development"
    Project     = "TerraformDemo"
    Role        = "WebServer"
  }
}

resource "aws_instance" "dev_private_instance" {
  ami                         = data.aws_ami.latest_amazon_linux.id
  instance_type               = "t2.small"
  key_name                    = aws_key_pair.my_key_pair.key_name
  subnet_id                   = data.terraform_remote_state.network.outputs.private_subnet_ids[0] # Use the first private subnet ID
  iam_instance_profile        = "SSM" # Ensure this profile exists in your AWS account
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.dev_instance_sg.id]
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Welcome to the Dev Private Instance</h1>" > /var/www/html/index.html
            EOF
  tags = {
    Name        = "DevPrivateInstance"
    Owner       = "DevTeam"
    Environment = "Development"
    Project     = "TerraformDemo"
    Role        = "WebServer"
  }
}


resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "my_key_pair" {
  key_name   = "my_key_pair"
  public_key = tls_private_key.private_key.public_key_openssh
}

resource "local_file" "private_key_pem" {
  filename        = "${aws_key_pair.my_key_pair.key_name}.pem"
  content         = tls_private_key.private_key.private_key_pem
  file_permission = "0400"
}

resource "aws_security_group" "dev_instance_sg" {
  name        = "dev_instance_sg"
  description = "Security group for the development instance"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.aws_security_IP]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.aws_security_IP]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.aws_security_IP]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
