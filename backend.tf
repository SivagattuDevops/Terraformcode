terraform {
  backend "s3" {
    bucket         = "bitbucket-terraform-state-1"
    key            = "infra.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
