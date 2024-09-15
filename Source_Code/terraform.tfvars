# Region for infrastructure creation
region = "us-east-1"

# IAM Instance role
profile_name = "EC2roleforSSMandS3"

# VPC and Network parameters
vpc_cidr = "10.0.0.0/16"
public_subnet1_cidr = "10.0.0.0/24"
AZ1 = "us-east-1a"
AZ2 = "us-east-1b"
public_subnet2_cidr = "10.0.1.0/24"
app_private_subnet1_cidr = "10.0.2.0/24"
app_private_subnet2_cidr = "10.0.3.0/24"
DB_private_subnet1_cidr = "10.0.4.0/24"
DB_private_subnet2_cidr = "10.0.5.0/24"
myIP = "103.183.229.240/32"

# RDS Parameters
db_identifier = "webappdb"
db_storage = 10
db_name = "webappdb"
db_engine = "mysql"
db_engine_version = "5.7"
db_instance_class = "db.t3.small"
db_username = "admin"
db_password = "Harshal17091998"
db_replica_identifier = "webappdb-replica"

# Internal Load Balancer
internal_lb_TG = "AppTierTG"
internal_lb_name = "App-Tier-Internal-LB"

# Backend Austoscaling Group
app_tier_launch_template_name = "AppTier-Launch-Template"
app_instance_type = "t2.micro"
app_tier_ASG_name = "App-Tier-ASG"
max_capactiy_of_app_instances = 2
min_capactiy_of_app_instances = 2
desired_capacity_of_app_instances = 2

# Internet Facing Load Balancer
interent_facing_lb_TG = "WebTierTG"
internet_facing_lb_name = "Internet-Facing-LB"

# Frontend Austoscaling Group
web_tier_launch_template_name = "WebTier-Launch-Template"
web_instance_type = "t2.micro"
web_tier_ASG_name = "Web-Tier-ASG"
max_capacity_of_web_insatances = 2
min_capacity_of_web_insatances = 2
desired_capacity_of_web_insatances = 2

# Image Name
web_image_name = "Web-Tier-Image*"
app_image_name = "App-Tier-Image*"