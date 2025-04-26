provider "aws" {
    region = "us-east-1"
  }
  
  resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
  }
  
  resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main.id
  }
  
  resource "aws_subnet" "main" {
    vpc_id            = aws_vpc.main.id
    cidr_block        = "10.0.1.0/24"
    map_public_ip_on_launch = true
  }
  
  resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.main.id
  
    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.igw.id
    }
  }
  
  
  resource "aws_route_table_association" "public_association" {
    subnet_id      = aws_subnet.main.id
    route_table_id = aws_route_table.public_rt.id
  }
  
  
  resource "aws_security_group" "allow_ssh" {
    name        = "allow_ssh"
    description = "Allow SSH inbound traffic"
    vpc_id      = aws_vpc.main.id
    ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["49.207.232.228/32"] # Replace with your public IP
    }
    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  
  resource "aws_key_pair" "generated_key" {
    key_name   = "terraform"
    public_key = file("~/.ssh/terraform.pub")
  }
  
  
  resource "aws_instance" "web" {
    ami           = "ami-0c02fb55956c7d316" # Amazon Linux 2 AMI (update as needed)
    instance_type = "t2.micro"
    subnet_id         = aws_subnet.main.id
    vpc_security_group_ids = [aws_security_group.allow_ssh.id] # Changed to use security group ID
    associate_public_ip_address = true
    key_name = aws_key_pair.generated_key.key_name
    tags = {
      Name = "Terraform-EC2"
    }
  }
  