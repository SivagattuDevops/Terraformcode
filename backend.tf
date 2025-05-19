terraform {
  backend "s3" {
    bucket         = "mygattucloudwatch"
    key            = "infra.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
