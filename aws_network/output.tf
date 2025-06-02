output "available_azs" {
  value = data.aws_availability_zones.available.names
}

output "public_subnet_ids" {
  value = [for subnet in aws_subnet.dev_public_subnet : subnet.id]
}

output "public_subnet_cidr_blocks" {
  value = [for subnet in aws_subnet.dev_public_subnet : subnet.cidr_block]
}

output "private_subnet_ids" {
  value = [for subnet in aws_subnet.dev_private_subnet : subnet.id]
}
output "private_subnet_cidr_blocks" {
  value = [for subnet in aws_subnet.dev_private_subnet : subnet.cidr_block]
}
output "vpc_id" {
  value = aws_vpc.dev_vpc.id
}
output "internet_gateway_id" {
  value = aws_internet_gateway.dev_igw.id
}

output "public_route_table_id" {
  value = aws_route_table.dev_public_rt.id
}
