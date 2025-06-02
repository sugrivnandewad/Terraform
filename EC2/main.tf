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
resource "aws_instance" "dev_instance" {
  ami           = "ami-0c55b159cbfafe1f0" # Example AMI, replace with a valid one
  instance_type = "t2.micro"
  key_name      = aws_key_pair.my_key_pair.key_name
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
