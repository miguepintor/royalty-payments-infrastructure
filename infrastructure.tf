provider "aws" {
  region = "eu-west-1"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "main-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Managed = "terraform"
  }
}

module "alb" {
  source = "./resources/alb"

  tags = {
    Environment = "int"
    Managed     = "terraform"
  }
  app_name    = "royalties"
  environment = "int"

  internal    = false
  vpc_id      = "${module.vpc.vpc_id}"
  alb_subnets = "${module.vpc.public_subnets}"
  ingress_cidrs = {
    "Whole World" = "0.0.0.0/0"
  }
  egress_cidrs = "${zipmap(
    ["Private Subnet 1", "Private Subnet 2"],
    module.vpc.private_subnets_cidr_blocks
  )}"
}

resource "aws_ecs_cluster" "int" {
  name = "cluster-int"
}

module "service" {
  source = "./resources/service"

  tags = {
    Environment = "int"
    Managed     = "terraform"
  }
  app_name    = "royalties"
  environment = "int"

  cluster_name          = "${aws_ecs_cluster.int.name}"
  vpc_id                = "${module.vpc.vpc_id}"
  service_subnets       = "${module.vpc.private_subnets}"
  alb_security_group_id = "${module.alb.alb_security_group_id}"
  alb_target_group_arn  = "${module.alb.alb_target_group_arn}"
  enable_autoscaling    = true
}

module "ecr" {
  source  = "cloudposse/ecr/aws"
  version = "0.7.0"
  name    = "royalty-ecr"
  tags = {
    Environment = "int"
    Managed     = "terraform"
  }
}