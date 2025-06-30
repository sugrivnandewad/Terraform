variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "ap-south-1"

}
variable "aws_security_IP" {
  description = "The IP address to allow SSH access to the EC2 instances"
  type        = string
  default     = "0.0.0.0/0" # Change this to your specific IP address or CIDR block for security purposes
}

