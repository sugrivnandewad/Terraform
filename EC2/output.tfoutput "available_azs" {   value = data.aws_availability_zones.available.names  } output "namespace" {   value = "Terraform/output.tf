output "available_azs" {
  value = data.aws_availability_zones.available.names

}
output "namespace" {
  value = "Terraform/EC2"
  
}

output "ec2_instance_ids" {
  value = [for instance in aws_instance.dev_ec2_instance : instance.id]
  
}
