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
  iam_instance_profile        = "SSM"                                                             # Ensure this profile exists in your AWS account
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.dev_instance_sg.id]
  user_data                   = <<-EOF
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
    cidr_blocks = [var.aws_security_IP] # Corrected CIDR block
  }
}

# Find a certificate that is issued
data "aws_acm_certificate" "issued" {
  domain   = "tf.example.com"
  statuses = ["ISSUED"]
}

# Find a certificate issued by (not imported into) ACM
data "aws_acm_certificate" "amazon_issued" {
  domain      = "tf.example.com"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

# Find a RSA 4096 bit certificate
data "aws_acm_certificate" "rsa_4096" {
  domain    = "tf.example.com"
  key_types = ["RSA_4096"]
}

resource "aws_lb" "dev_public_lb" {
  name               = "dev-public-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.dev_instance_sg.id]
  subnets            = data.terraform_remote_state.network.outputs.public_subnet_ids
}
resource "aws_lb_target_group" "dev_target_group" {
  name        = "dev-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id
  target_type = "instance"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "dev_private_instance" {
  target_group_arn = aws_lb_target_group.dev_target_group.arn
  target_id        = aws_instance.dev_private_instance.id
  port             = 80
}

resource "aws_lb_listener" "dev_http_listener" {
  load_balancer_arn = aws_lb.dev_public_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dev_target_group.arn
  }
}
