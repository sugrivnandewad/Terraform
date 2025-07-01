output "aws_db_instance" {
    value = aws_db_instance.dev_db_instance
}
output "aws_db_subnet_group" {
    value = aws_db_subnet_group.dev_db_subnet_group
}
output "aws_db_security_group" {
    value = aws_security_group.dev_db_sg
}
output "db_instance_endpoint" {
    value = aws_db_instance.dev_db_instance.endpoint
}
output "db_instance_arn" {
    value = aws_db_instance.dev_db_instance.arn
}
