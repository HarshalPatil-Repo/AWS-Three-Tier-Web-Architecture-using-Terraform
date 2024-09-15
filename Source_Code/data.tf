data "aws_iam_instance_profile" "existing_role" {
  name = var.profile_name
}

data "aws_ami" "web_ami" {
  most_recent = true
  owners      = ["self"]

  # Filter to find your custom AMI
  filter {
    name   = "name"
    values = [var.web_image_name] # Adjust this to your AMI name
  }
}

data "aws_ami" "app_ami" {
  most_recent = true
  owners      = ["self"]

  # Filter to find your custom AMI
  filter {
    name   = "name"
    values = [var.app_image_name] # Adjust this to your AMI name
  }
}