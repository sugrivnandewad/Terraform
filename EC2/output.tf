output "ec2_instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.dev_instance.id
}

output "ec2_private_instance_id" {
  description = "The ID of the private EC2 instance"
  value       = aws_instance.dev_private_instance.id
}
