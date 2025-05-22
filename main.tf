# ================================
# PROVIDERS
# ================================
provider "aws" {
  alias  = "region1"
  region = var.region1
}

provider "aws" {
  alias  = "region2"
  region = var.region2
}

provider "aws" {
  alias  = "useast1"
  region = "us-east-1" # Required for ACM with CloudFront
}

# ================================
# VPC MODULES
# ================================
module "vpc_region1" {
  source             = "./modules/vpc"
  providers          = { aws = aws.region1 }
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.azs_region1
  name               = "region1"
}

module "vpc_region2" {
  source             = "./modules/vpc"
  providers          = { aws = aws.region2 }
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.azs_region2
  name               = "region2"
}

# ================================
# SECURITY GROUPS
# ================================
module "security_group_region1" {
  source      = "./modules/security_group"
  providers   = { aws = aws.region1 }
  vpc_id      = module.vpc_region1.vpc_id
  name_prefix = "region1"
}

module "security_group_region2" {
  source      = "./modules/security_group"
  providers   = { aws = aws.region2 }
  vpc_id      = module.vpc_region2.vpc_id
  name_prefix = "region2"
}

# ================================
# EC2 INSTANCES
# ================================
module "ec2_region1" {
  source             = "./modules/ec2"
  providers          = { aws = aws.region1 }
  ami_id             = var.ami_id
  instance_type      = var.instance_type
  subnet_ids         = module.vpc_region1.public_subnets
  security_group_id  = module.security_group_region1.security_group_id
  key_name           = var.key_name
  instance_count     = 2
  name_prefix        = "region1"
}

module "ec2_region2" {
  source             = "./modules/ec2"
  providers          = { aws = aws.region2 }
  ami_id             = var.ami_id
  instance_type      = var.instance_type
  subnet_ids         = module.vpc_region2.public_subnets
  security_group_id  = module.security_group_region2.security_group_id
  key_name           = var.key_name
  instance_count     = 2
  name_prefix        = "region2"
}

# ================================
# APPLICATION LOAD BALANCERS
# ================================
module "elb_region1" {
  source            = "./modules/elb"
  providers         = { aws = aws.region1 }
  subnet_ids        = module.vpc_region1.public_subnets
  security_group_id = module.security_group_region1.security_group_id
  instance_ids      = module.ec2_region1.instance_ids
  vpc_id            = module.vpc_region1.vpc_id
}

module "elb_region2" {
  source            = "./modules/elb"
  providers         = { aws = aws.region2 }
  subnet_ids        = module.vpc_region2.public_subnets
  security_group_id = module.security_group_region2.security_group_id
  instance_ids      = module.ec2_region2.instance_ids
  vpc_id            = module.vpc_region2.vpc_id
}

# ================================
# S3 WITH CROSS-REGION REPLICATION
# ================================
module "s3" {
  source     = "./modules/s3"
  providers  = {
    aws.region1 = aws.region1
    aws.region2 = aws.region2
  }
  bucket_prefix = var.bucket_prefix
}

# ================================
# RDS PRIMARY + REPLICA
# ================================
module "rds" {
  source = "./modules/rds"
  providers = {
    aws.region1 = aws.region1
    aws.region2 = aws.region2
  }

  db_identifier             = var.db_identifier
  db_username               = var.db_username
  db_password               = var.db_password
  instance_class            = var.instance_class
  allocated_storage         = var.allocated_storage
  engine                    = var.engine
  engine_version            = var.engine_version
  subnet_ids_region1        = module.vpc_region1.private_subnets
  subnet_ids_region2        = module.vpc_region2.private_subnets
  security_group_id_region1 = module.security_group_region1.security_group_id
  security_group_id_region2 = module.security_group_region2.security_group_id
}

# ================================
# ROUTE 53 DNS FAILOVER
# ================================
module "route53" {
  source            = "./modules/route53"
  providers         = { aws = aws.region1 }
  domain_name       = var.domain_name
  primary_alb_dns   = module.elb_region1.alb_dns
  secondary_alb_dns = module.elb_region2.alb_dns
  hosted_zone_id    = var.hosted_zone_id
}


# ================================
# CLOUDFRONT + CUSTOM DOMAIN (SSL)
# ================================
module "cloudfront_custom" {
  source = "./modules/cloudfront_custom_domain"
  providers = {
    aws.useast1 = aws.useast1
    aws         = aws.region1
  }
  domain_name    = var.domain_name
  bucket_name    = module.s3.primary_bucket_name
  hosted_zone_id = var.hosted_zone_id
}
