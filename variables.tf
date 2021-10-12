variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "pub_key_path" {}
variable "priv_key_path" {}

variable "region" {
  description = "Enter region"
  default     = "eu-central-1"
  type        = string
}

variable "instance_type" {
  description = "Enter Instance Type"
  type        = string
  default     = "t3.micro"
}

variable "ami" {
  type        = string
  description = "Enter AMI"
  default     = "ami-05f7491af5eef733a"
}

variable "srv_count" {
  description = "Enter the number of WS instances you need to create: "
  default     = 4
}

variable "vpc_subnet" {
  description = "New VPC CIDR block"
  default = "172.0.0.0/16"
}

variable "username" {
  description = "Enter username for your instance"
  default = "ubuntu"
}

locals {
  cidr_bastion = "${aws_instance.bastion_host.private_ip}/32"
  count_avz = length(data.aws_availability_zones.available.names)
  names_avz = data.aws_availability_zones.available.names[*]
}