output "ec2_public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_eip.app_server_eip.public_ip
}

output "rds_endpoint" {
  description = "The endpoint of the RDS database"
  value       = aws_db_instance.mysql.endpoint
}
