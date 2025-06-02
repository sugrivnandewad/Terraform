
variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "ap-south-1"

}
variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.155.0.0/16"
}
variable "public_subnet_cidr_blocks" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
  default = [
    "10.155.1.0/24",
    "10.155.2.0/24",
    "10.155.3.0/24"
  ]
}
variable "private_subnet_cidr_blocks" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
  default = [
    "10.155.4.0/24",
    "10.155.5.0/24",
    "10.155.6.0/24"
  ]
}
variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Name        = "dev_vpc"
    Project     = "terraform-aws"
    Owner       = "DevOps Team"
    Environment = "Development"
  }
}


variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = []
}
variable "enable_internet_gateway" {
  description = "Enable or disable the creation of an Internet Gateway"
  type        = bool
  default     = true
}
variable "enable_nat_gateway" {
  description = "Enable or disable the creation of a NAT Gateway"
  type        = bool
  default     = false
}
variable "nat_gateway_allocation_id" {
  description = "EIP allocation ID for the NAT Gateway (required if enable_nat_gateway is true)"
  type        = string
  default     = ""
  validation {
    condition     = var.enable_nat_gateway ? var.nat_gateway_allocation_id != "" : true
    error_message = "nat_gateway_allocation_id must be provided if enable_nat_gateway is true."
  }
}


variable "destination_cidr_block" {
  description = "Destination CIDR block for the public route"
  type        = string
  default     = "0.0.0.0/0"

}
