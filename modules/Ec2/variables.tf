variable "vpc_id" {
  description = "The VPC ID to use for EC2 and security group"
  type        = string
}

variable "public_subnet" {
  description = "The public subnet ID for EC2 instance"
  type        = string
}
