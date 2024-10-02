# VPC Module
module "vpc" {
  source      = "./modules/vpc"
  cidr_block  = var.cidr_block
  vpc_name    = var.aws_vpc
}

# Subnet Module
module "subnets" {
  source               = "./modules/subnet"
  vpc_id               = module.vpc.vpc_id
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  tags                 = var.tags
}

# Internet Gateway Module
module "internet_gateway" {
  source = "./modules/igw"
  vpc_id = module.vpc.vpc_id
  tags   = var.tags
}

# Elastic IP Resource for NAT Gateway
resource "aws_eip" "nat" {
  tags = {
    Name = "NAT Elastic IP"
  }
}

# NAT Gateway Module
module "nat_gateway" {
  source            = "./modules/nat"
  eip_allocation_id = aws_eip.nat.id
  subnet_id         = module.subnets.public_subnet_ids[0]
  tags              = var.tags
}

# Route Table Module
module "route_tables" {
  source              = "./modules/route_table"
  vpc_id              = module.vpc.vpc_id
  internet_gateway_id = module.internet_gateway.internet_gateway_id
  nat_gateway_id      = module.nat_gateway.nat_gateway
  public_subnet_ids   = module.subnets.public_subnet_ids
  private_subnet_ids  = module.subnets.private_subnet_ids
  tags                = var.tags
}


module "security_group" {
  source              = "./modules/sg"
  vpc_id              = module.vpc.vpc_id
  security_group_name = "jenkins-SG"
  ingress_ports       = var.ingress_ports
  egress_ports        = var.egress_ports
}


# EC2 Instance Module
module "instance" {
  source           = "./modules/ec2"
  ami              = var.ami_id
  instance_type    = var.instance_type
  subnet_id        = module.subnets.public_subnet_ids[0]
  key_name         = var.key_name
  security_group_id  = module.security_group.security_group_id
}


# Auto Scaling Group Module
module "auto_scaling" {
  source            = "./modules/asg"
  ami_id            = var.ami_id
  instance_type     = var.instance_type
  key_name          = var.key_name
  private_subnets   = module.subnets.private_subnet_ids
  security_group_id = module.security_group.security_group_id
  desired_capacity  = var.desired_capacity
  max_size          = var.max_size
  min_size          = var.min_size
  target_group_arn  = module.alb.target_group_arn
}

# Application Load Balancer Module
module "alb" {
  source            = "./modules/alb"
  security_group_id = module.security_group.security_group_id
  subnets           = module.subnets.public_subnet_ids
  vpc_id            = module.vpc.vpc_id
  port              = var.port
  listener_port     = var.listener_port
}

# S3 Bucket Module
module "s3" {
  source      = "./modules/s3"
  bucket_name = "my-jenkins-deploy-bucket-tool"
}
