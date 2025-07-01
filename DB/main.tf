provider "aws" {
    region = "ap-south-1"
  
}

terraform {
  backend "s3" {
    bucket = "terraform-sbn"
    key    = "dev/db/terraform.tfstate"
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

resource "aws_db_subnet_group" "dev_db_subnet_group" {
    name    = "dev-db-subnet-group"
    subnet_ids = data.terraform_remote_state.network.outputs.private_subnet_ids
    tags = {
        Name        = "DevDBSubnetGroup"
        Environment = "Development"
        Project     = "TerraformDemo"
    }
}
resource "aws_security_group" "dev_db_sg" {
    name        = "dev-db-sg"
    description = "Security group for Dev DB instance"
    vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

    ingress {
        from_port   = 3306
        to_port     = 3306
        protocol    = "tcp"
        cidr_blocks = ["10.155.0.0/16"] # Allow access from the VPC CIDR block
    }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1" # Allow all outbound traffic
        cidr_blocks = ["0.0.0.0/0"] # Allow access from anywhere    
    }
    tags = {
        Name        = "DevDBSecurityGroup"
        Environment = "Development"
        Project     = "TerraformDemo"
    }
}

resource "aws_db_instance" "dev_db_instance" {
    identifier        = "dev-db-instance"
    engine            = "mysql"
    engine_version    = "8.0"
    instance_class    = "db.t3.micro"
    allocated_storage = 20
    storage_type      = "gp2"
    db_subnet_group_name = aws_db_subnet_group.dev_db_subnet_group.name
    username         = "admin"
    password         = "AdminPassword123!" # Use a secure method to manage passwords
    skip_final_snapshot = true
    publicly_accessible = false
    vpc_security_group_ids = [aws_security_group.dev_db_sg.id]
    depends_on = [ aws_db_subnet_group.dev_db_subnet_group, aws_security_group.dev_db_sg]
    tags = {
        Name        = "DevDBInstance"
        Environment = "Development"
        Project     = "TerraformDemo"
    }
}
