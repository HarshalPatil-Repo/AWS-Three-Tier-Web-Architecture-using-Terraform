######################################################
# VPC
######################################################

resource "aws_vpc" "webVPC" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "webappVPC"
  }
}

###################################################################
# Creating 6 Subnets (2 Public and 4 Private )
###################################################################

# Public Subnets

resource "aws_subnet" "public_subnet1" {
  vpc_id                  = aws_vpc.webVPC.id
  cidr_block              = var.public_subnet1_cidr
  availability_zone       = var.AZ1
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Web-Subnet-AZ1"
  }
}

resource "aws_subnet" "public_subnet2" {
  vpc_id                  = aws_vpc.webVPC.id
  cidr_block              = var.public_subnet2_cidr
  availability_zone       = var.AZ2
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Web-Subnet-AZ2"
  }
}

# Private Subnets

resource "aws_subnet" "app_private_subnet1" {
  vpc_id            = aws_vpc.webVPC.id
  cidr_block        = var.app_private_subnet1_cidr
  availability_zone = var.AZ1

  tags = {
    Name = "Private-App-Subnet-AZ1"
  }
}

resource "aws_subnet" "app_private_subnet2" {
  vpc_id            = aws_vpc.webVPC.id
  cidr_block        = var.app_private_subnet2_cidr
  availability_zone = var.AZ2

  tags = {
    Name = "Private-App-Subnet-AZ2"
  }
}

# Database Subnets

resource "aws_subnet" "DB_private_subnet1" {
  vpc_id            = aws_vpc.webVPC.id
  cidr_block        = var.DB_private_subnet1_cidr
  availability_zone = var.AZ1

  tags = {
    Name = "Private-DB-Subnet-AZ1"
  }
}

resource "aws_subnet" "DB_private_subnet2" {
  vpc_id            = aws_vpc.webVPC.id
  cidr_block        = var.DB_private_subnet2_cidr
  availability_zone = var.AZ2

  tags = {
    Name = "Private-DB-Subnet-AZ2"
  }
}
#####################################
# Internet Gateway
#####################################

resource "aws_internet_gateway" "webapp-igw" {
  vpc_id = aws_vpc.webVPC.id

  tags = {
    Name = "web-app-IGW"
  }
}
#############################################################
# Creating 2 NAT Gateways in both Public Subnets
#############################################################

// First Create two ellastic IP's for both NAT gateways

resource "aws_eip" "eip1" {
  domain = "vpc"
}

resource "aws_eip" "eip2" {
  domain = "vpc"
}

// Now Create both NAT Gateways

resource "aws_nat_gateway" "NAT_AZ1" {
  allocation_id = aws_eip.eip1.id
  subnet_id     = aws_subnet.public_subnet1.id

  tags = {
    Name = "NAT-GW-AZ1"
  }

  // To ensure proper ordering, it is recommended to add an explicit dependency on the Internet Gateway for the VPC
  depends_on = [aws_internet_gateway.webapp-igw]
}

resource "aws_nat_gateway" "NAT_AZ2" {
  allocation_id = aws_eip.eip2.id
  subnet_id     = aws_subnet.public_subnet2.id

  tags = {
    Name = "NAT-GW-AZ2"
  }

  // To ensure proper ordering, it is recommended to add an explicit dependency on the Internet Gateway for the VPC
  depends_on = [aws_internet_gateway.webapp-igw]
}

###################################################################################
# Create 3 Route Tables (1 for Public subnets and 2 for Private subnets)
###################################################################################

// Creating Route Table and associating with Public Subnets

resource "aws_route_table" "RT_Public" {
  vpc_id = aws_vpc.webVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.webapp-igw.id
  }

  tags = {
    Name = "PublicRouteTable"
  }
}

resource "aws_route_table_association" "RT_PublicSubnet1_Association" {
  subnet_id      = aws_subnet.public_subnet1.id
  route_table_id = aws_route_table.RT_Public.id
}

resource "aws_route_table_association" "RT_PublicSubnet2_Association" {
  subnet_id      = aws_subnet.public_subnet2.id
  route_table_id = aws_route_table.RT_Public.id
}

// Creating Route Tables and associtating with Private Subnets

resource "aws_route_table" "RT_Private1" {
  vpc_id = aws_vpc.webVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.NAT_AZ1.id
  }

  tags = {
    Name = "PrivateRouteTableAZ-1"
  }
}

resource "aws_route_table_association" "RT_PrivateSubnet1_Association" {
  subnet_id      = aws_subnet.app_private_subnet1.id
  route_table_id = aws_route_table.RT_Private1.id
}

resource "aws_route_table" "RT_Private2" {
  vpc_id = aws_vpc.webVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.NAT_AZ2.id
  }

  tags = {
    Name = "PrivateRouteTableAZ-2"
  }
}

resource "aws_route_table_association" "RT_PrivateSubnet2_Association" {
  subnet_id      = aws_subnet.app_private_subnet2.id
  route_table_id = aws_route_table.RT_Private2.id
}

##################################################
# Creating Security Groups On Each layer
##################################################
// Internet facing load balancer security group

resource "aws_security_group" "internet-facing-lb-sg" {
  name        = "Internet-facing-lb-sg"
  description = "Internet facing load balancer security group"
  vpc_id      = aws_vpc.webVPC.id

  tags = {
    Name = "Internet-facing-lb-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "HTTP" {
  security_group_id = aws_security_group.internet-facing-lb-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "All_Traffic" {
  security_group_id = aws_security_group.internet-facing-lb-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" // semantically equivalent to all ports
}

// Web Tier instances Security Group

resource "aws_security_group" "web-tier-sg" {
  name        = "Web-Tier-sg"
  description = "Security Group for Web Tier"
  vpc_id      = aws_vpc.webVPC.id

  tags = {
    Name = "Web-Tier-sg"
  }
}

resource "aws_security_group_rule" "web-tier-sg-ingress-rule1" {
  security_group_id        = aws_security_group.web-tier-sg.id
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.internet-facing-lb-sg.id
}

resource "aws_security_group_rule" "web-tier-sg-ingress-rule2" {
  security_group_id = aws_security_group.web-tier-sg.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [var.myIP] // Mention your current IP in terraform.tfvars
}

resource "aws_security_group_rule" "web-tier-sg-egress-rule" {
  security_group_id = aws_security_group.web-tier-sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

// Internal Load Balancer Securiity Group

resource "aws_security_group" "internal-lb-sg" {
  name        = "Internal-lb-sg"
  description = "Security Group for Internal Load Balancer"
  vpc_id      = aws_vpc.webVPC.id

  tags = {
    Name = "Internal-lb-sg"
  }
}

resource "aws_security_group_rule" "internal-lb-sg-ingress-rule" {
  security_group_id        = aws_security_group.internal-lb-sg.id
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.web-tier-sg.id
}

resource "aws_security_group_rule" "internal-lb-sg-egress-rule" {
  security_group_id = aws_security_group.internal-lb-sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

// Private Instance security group

resource "aws_security_group" "private-instance-sg" {
  name        = "Private-Instance-sg"
  description = "Private Instance security group"
  vpc_id      = aws_vpc.webVPC.id

  tags = {
    Name = "Private-Instance-sg"
  }
}

resource "aws_security_group_rule" "private-instance-sg-ingress-rule1" {
  security_group_id        = aws_security_group.private-instance-sg.id
  type                     = "ingress"
  from_port                = 4000 // Backend app supoorts port 4000
  to_port                  = 4000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.internal-lb-sg.id
}
resource "aws_security_group_rule" "private-instance-sg-ingress-rule2" {
  security_group_id = aws_security_group.private-instance-sg.id
  type              = "ingress"
  from_port         = 4000 // Backend app supoorts port 4000
  to_port           = 4000
  protocol          = "tcp"
  cidr_blocks       = [var.myIP] // Mention your current IP in terraform.tfvars
}

resource "aws_security_group_rule" "private-instance-sg-egress-rule" {
  security_group_id = aws_security_group.private-instance-sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

// Database Security Group

resource "aws_security_group" "database-sg" {
  name        = "Database-sg"
  description = "Database Security Group"
  vpc_id      = aws_vpc.webVPC.id

  tags = {
    Name = "Database-sg"
  }
}

resource "aws_security_group_rule" "database-sg-ingress-rule" {
  security_group_id        = aws_security_group.database-sg.id
  type                     = "ingress"
  from_port                = 3306 // Here we are using MYSQL/Aurora Database with 3306 port
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.private-instance-sg.id
}
resource "aws_security_group_rule" "database-sg-egress-rule" {
  security_group_id = aws_security_group.database-sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

#################################################################
# MySQL Database with Replica in another availability zone
#################################################################

# DB Subnet Group
resource "aws_db_subnet_group" "webappdb-subnet-group" {
  name       = "webappdb-subnet-group"
  subnet_ids = [aws_subnet.DB_private_subnet1.id, aws_subnet.DB_private_subnet2.id]

  tags = {
    Name = "webappdb-subnet-group"
  }
}

resource "aws_db_parameter_group" "default" {
  name   = "rds-pg"
  family = "mysql5.7"

  parameter {
    name  = "character_set_server"
    value = "utf8"
  }

  parameter {
    name  = "character_set_client"
    value = "utf8"
  }
}

resource "aws_db_instance" "webappdb" {
  identifier              = var.db_identifier
  allocated_storage       = var.db_storage
  db_name                 = var.db_name
  engine                  = var.db_engine
  engine_version          = var.db_engine_version
  instance_class          = var.db_instance_class
  username                = var.db_username
  password                = var.db_password
  parameter_group_name    = aws_db_parameter_group.default.name
  skip_final_snapshot     = true
  publicly_accessible     = false
  db_subnet_group_name    = aws_db_subnet_group.webappdb-subnet-group.name
  multi_az                = true
  backup_retention_period = 1
  vpc_security_group_ids  = [aws_security_group.database-sg.id]
}

resource "aws_db_instance" "webappdb-replica" {
  replicate_source_db     = aws_db_instance.webappdb.identifier
  backup_retention_period = 7
  identifier              = var.db_replica_identifier
  instance_class          = var.db_instance_class
  skip_final_snapshot     = true
  publicly_accessible     = false
  apply_immediately       = true
  vpc_security_group_ids  = [aws_security_group.database-sg.id]
}


##########################################
# Internal Load Balancer
##########################################

resource "aws_lb_target_group" "apptierTG" {
  name            = var.internal_lb_TG
  port            = 4000
  protocol        = "HTTP"
  vpc_id          = aws_vpc.webVPC.id
  ip_address_type = "ipv4"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 20
    timeout             = 5
    path                = "/health"

  }
}

resource "aws_lb" "internal-lb" {
  name               = var.internal_lb_name
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.internal-lb-sg.id]
  subnets            = [aws_subnet.app_private_subnet1.id, aws_subnet.app_private_subnet2.id]
  ip_address_type    = "ipv4"
}

resource "aws_lb_listener" "internal-lb-listener" {
  load_balancer_arn = aws_lb.internal-lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.apptierTG.arn
  }
}

#############################################
# App Tier Auto Scaling Group
#############################################

resource "aws_launch_template" "apptier-launch-template" {
  name                   = var.app_tier_launch_template_name
  image_id               = data.aws_ami.app_ami.id
  instance_type          = var.app_instance_type
  vpc_security_group_ids = [aws_security_group.private-instance-sg.id]
  iam_instance_profile {
    name = var.profile_name
  }
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 8
      volume_type           = "gp3"
      iops                  = 3000
      delete_on_termination = true
      encrypted             = false
      throughput            = 125
    }
  }
}

resource "aws_autoscaling_group" "app-tier-ASG" {
  name                      = var.app_tier_ASG_name
  max_size                  = var.max_capactiy_of_app_instances
  min_size                  = var.min_capactiy_of_app_instances
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = var.desired_capacity_of_app_instances
  force_delete              = true
  target_group_arns         = [aws_lb_target_group.apptierTG.arn]
  launch_template {
    id = aws_launch_template.apptier-launch-template.id
  }
  vpc_zone_identifier = [aws_subnet.app_private_subnet1.id, aws_subnet.app_private_subnet2.id]

}

###########################################
# Internet Facing Load Balancer
###########################################

resource "aws_lb_target_group" "webtierTG" {
  name            = var.interent_facing_lb_TG
  port            = 80
  protocol        = "HTTP"
  vpc_id          = aws_vpc.webVPC.id
  ip_address_type = "ipv4"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 20
    timeout             = 5
    path                = "/"

  }
}

resource "aws_lb" "internet-facing-lb" {
  name               = var.internet_facing_lb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.internet-facing-lb-sg.id]
  subnets            = [aws_subnet.public_subnet1.id, aws_subnet.public_subnet2.id]
  ip_address_type    = "ipv4"
}

resource "aws_lb_listener" "internet-facing-lb-listener" {
  load_balancer_arn = aws_lb.internet-facing-lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webtierTG.arn
  }
}

#############################################
# Web Tier Auto Scaling Group
#############################################

resource "aws_launch_template" "webtier-launch-template" {
  name                   = var.web_tier_launch_template_name
  image_id               = data.aws_ami.web_ami.id
  instance_type          = var.web_instance_type
  vpc_security_group_ids = [aws_security_group.web-tier-sg.id]
  iam_instance_profile {
    name = var.profile_name
  }
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 8
      volume_type           = "gp3"
      iops                  = 3000
      delete_on_termination = true
      encrypted             = false
      throughput            = 125
    }
  }
}

resource "aws_autoscaling_group" "web-tier-ASG" {
  name                      = var.web_tier_ASG_name
  max_size                  = var.max_capacity_of_web_insatances
  min_size                  = var.min_capacity_of_web_insatances
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = var.desired_capacity_of_web_insatances
  force_delete              = true
  target_group_arns         = [aws_lb_target_group.webtierTG.arn]
  launch_template {
    id = aws_launch_template.webtier-launch-template.id
  }
  vpc_zone_identifier = [aws_subnet.public_subnet1.id, aws_subnet.public_subnet2.id]

}

