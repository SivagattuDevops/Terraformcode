# Terraform configuration for EC2 with Route53 and Apache setup

provider "aws" {
  region = "us-east-1"
}

# 1. Create VPC, Subnet, Internet Gateway, Route Table (optional: use default VPC)
data "aws_vpc" "default" {
  default = true
}

/* data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}
*/
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# 2. Security Group allowing HTTP (port 80)
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow HTTP, HTTPS, SSH"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

/*
resource "aws_key_pair" "default" {
  key_name   = "my-key"
  public_key = file("~/.ssh/terraform_key.pub")  # replace path if needed
}
*/

# 4. EC2 instance with Apache installation
resource "aws_instance" "web" {
  ami                         = "ami-0c02fb55956c7d316" # Ubuntu 22.04 in us-east-1
  instance_type               = "t2.micro"
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  key_name                    = "my-key"
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo systemctl enable apache2
              EOF

  tags = {
    Name = "TerraformWebServer"
  }
}

# 5. Allocate and associate Elastic IP
resource "aws_eip" "web_eip" {
  instance = aws_instance.web.id
  domain      = "vpc"
}

# 6. Hosted Zone (Public)
resource "aws_route53_zone" "public_zone" {
  name = "myroute53eip.in"
}

# 7. A Record in Route53 to point domain to EC2's EIP
resource "aws_route53_record" "web_record" {
  zone_id = aws_route53_zone.public_zone.zone_id
  name    = "www.myroute53eip.in"
  type    = "A"
  ttl     = 300
  records = [aws_eip.web_eip.public_ip]
}

output "ec2_public_ip" {
  value = aws_eip.web_eip.public_ip
}

output "domain_name" {
  value = aws_route53_record.web_record.name
}
