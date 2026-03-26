variable "aws_region" {
  description = "The AWS region to deploy the infrastructure in"
  type        = string
  default     = "us-east-1"
}

variable "db_username" {
  description = "The database admin username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "The database admin password"
  type        = string
  sensitive   = true
  default     = "Password123!"
}

variable "db_name" {
  description = "The name of the database to create"
  type        = string
  default     = "epicbook"
}

variable "key_name" {
  description = "Name of the EC2 key pair for SSH access"
  type        = string
  default     = "bookstore" # Updated with the user's newly created key pair
}
