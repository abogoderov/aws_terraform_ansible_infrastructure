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


locals { # Local variable to determine bastion host private ip
  cidr_bastion = "${aws_instance.bastion_host.private_ip}/32"
}