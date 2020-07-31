provider "aws" {
  region = "us-east-2"
  profile = "boto-int"
}

terraform {
  backend "s3" {
    bucket = "tf-state-aws-e2e-vpc"
    region = "us-east-2"
    key = "terraform.tfstate"
    profile = "boto-int"

  }
}

module "sns" {
  source        = "./sns"
  aws_region    = "us-east-2"
  email_target  = "praseed_mc@intuit.com"
  public_autoscaling_group = "${module.auto_scaling.public_autoscaling_group}"
}

module "vpc" {
  source        = "./vpc"
  vpc_cidr      = "10.0.0.0/16"
  public_cidrs  = ["10.0.1.0/24", "10.0.2.0/24","10.0.3.0/24"]
  private_cidrs = ["10.0.4.0/24", "10.0.5.0/24","10.0.6.0/24"]
  aws_region    = "us-east-2"
}

module "iam" {
  source = "./iam"
  aws_region    = "us-east-2"
}

module "alb" {
  source = "./alb"
  vpc_id = "${module.vpc.aws_vpc_id}"
  # instance1_id = "${module.ec2.instance1_id}"
  # instance2_id = "${module.ec2.instance2_id}"
  pub-subnet1 = "${module.vpc.pub-subnet1}"
  pub-subnet2 = "${module.vpc.pub-subnet2}"
  pub-subnet3 = "${module.vpc.pub-subnet3}"
  pri-subnet1 = "${module.vpc.pri-subnet1}"
  pri-subnet2 = "${module.vpc.pri-subnet2}"
  pri-subnet3 = "${module.vpc.pri-subnet3}"
  aws_region       = "us-east-2"
  public-sg-id = "${module.auto_scaling.public-sg-id}"
}

module "auto_scaling" {
  source           = "./auto_scaling"
  aws_region       = "us-east-2"
  vpc_id           = "${module.vpc.aws_vpc_id}"
  private_subnet_ids = "${module.vpc.pri_subnets}"
  public_subnet_ids  = "${module.vpc.pub_subnets}"
  private-target_group_arn  = "${module.alb.private-alb_target_group_arn}"
  public-target_group_arn  = "${module.alb.public-alb_target_group_arn}"
  alb-sg-id         = "${module.alb.alb-sg}"
  public_key       = "/tmp/id_rsa.pub"
  iam_profile      = "${module.iam.iam_profile}"
  max_no_instance = "5"
  min_no_instance = "3"
}