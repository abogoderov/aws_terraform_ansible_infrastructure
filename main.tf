provider "aws" {
  region     = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

data "aws_availability_zones" "available" {
  state =  "available"
}

resource "aws_key_pair" "sshkey" {
  key_name   = "mykey"
  public_key = file("${var.pub_key_path}")
}

resource "aws_instance" "ws_private_instance" { # Creating 3 same private instances 
  count = var.srv_count

  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id = aws_subnet.prv_subnet[count.index % local.count_avz].id
  #availability_zone           = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)] # Every Web server is in different AZ
  key_name                    = aws_key_pair.sshkey.key_name
  vpc_security_group_ids      = [aws_security_group.my_webserver.id]
  associate_public_ip_address = false

  tags = {
    Name = "Ngnix ${count.index}"
  }
}
resource "aws_instance" "bastion_host" { # Creating bastion host
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = aws_key_pair.sshkey.key_name
  vpc_security_group_ids = [aws_security_group.my_bastion.id]
  subnet_id = aws_subnet.pub_subnet[0].id

  tags = {
    Name = "Bastion_host"
  }


}

resource "aws_security_group" "my_webserver" { # Security group for web server
  name        = "WebServer Security Group"
  description = "My First SecurityGroup"
  vpc_id = aws_vpc.project_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${local.cidr_bastion}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {
    Name = "WebServer SecurityGroup"
  }

}

resource "aws_security_group" "my_bastion" { # Security group for web server
  name        = "Bastion Security Group"
  description = "My First SecurityGroup"
  vpc_id = aws_vpc.project_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {
    Name = "Bastion SecurityGroup"
  }
}

resource "aws_security_group" "elb_sg" {
  name        = "ELB security group"
  description = "sg to open 80 and 8080"
  vpc_id = aws_vpc.project_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
}
#--------------------------------------------------------------------------
# This code block creates classic load balancer
resource "aws_elb" "ws_balancer" {
  name               = "terraform-elb"
  #availability_zones = data.aws_availability_zones.available.names
  subnets = aws_subnet.pub_subnet[*].id
  security_groups = [aws_security_group.elb_sg.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  instances = aws_instance.ws_private_instance.*.id

}

resource "null_resource" "run_playbook" {

  provisioner "local-exec" {
    command     = "ansible-playbook playbook_deploy.yml"
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = [
    local_file.playbook_deploy

  ]
}

resource "local_file" "playbook_deploy" {
  content = templatefile("playbook_deploy.tmpl",{
    username = "${var.username}"
    }
  )
  filename = "playbook_deploy.yml"
  file_permission = "0600"
  depends_on = [local_file.AnsibleInventory]
}

# This code block provides instance info for Ansible inventory file
# 
resource "local_file" "AnsibleInventory" {
  content = templatefile("inventory.tmpl",
    {
      public-ip-bastion  = aws_instance.bastion_host.public_ip,
      public-dns-bastion = aws_instance.bastion_host.public_dns,
      sshkey             = "${var.priv_key_path}",
      username           = "${var.username}",
      private-dns        = aws_instance.ws_private_instance.*.private_dns,
      private-ip         = aws_instance.ws_private_instance.*.private_ip,
      private-id         = aws_instance.ws_private_instance.*.id
    }
  )
  filename        = "inventory"
  file_permission = "0600"
  depends_on = [aws_instance.ws_private_instance, 
                aws_instance.bastion_host, 
                aws_elb.ws_balancer,
                aws_nat_gateway.natgw_prv,
                aws_route_table.rt_prv,
                aws_route_table.rt_pub]
}