
provider "aws" {
    region = "us-east-1"
  }
/*

module "vpc" {
  source = "./modules/vpc"
}

module "ec2" {
  source = "./modules/Ec2"

  vpc_id         = module.vpc.vpc_id
  public_subnet  = module.vpc.public_subnet_id
}


module "s3" {
  source = "./modules/s3"
}



module "iam" {
  source = "./modules/iam"
}


module "cloudwatch_cloudtrail" {
  source = "./modules/cloudwatch_cloudtrail"
}



module "lambda" {
  source = "./modules/lambda"
}

*/

module "Route53" {
  source = "./modules/Route53"
}


