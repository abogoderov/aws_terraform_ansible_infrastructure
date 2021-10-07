provider "aws" {
  region = var.region
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
}

resource "aws_key_pair" "sshkey" {
  key_name   = "mykey"
  public_key = file("${var.pub_key_path}")
}

resource "aws_instance" "ws_private_instance" { # Creating 3 same private instances 
  count                  = 3

  ami                    = var.ami
  instance_type          = var.instance_type
  availability_zone      = data.aws_availability_zones.available.names[count.index] # Every Web server is in different AZ
  key_name               = aws_key_pair.sshkey.key_name
  vpc_security_group_ids = [aws_security_group.my_webserver.id]
  tags = {
    Name = "Ngnix ${count.index}-az-${data.aws_availability_zones.available.names[count.index]}"
  }
}
resource "aws_instance" "bastion_host" { # Creating bastion host
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = aws_key_pair.sshkey.key_name
  vpc_security_group_ids = [aws_security_group.my_bastion.id]


  tags = {
    Name = "Bastion_host"
  }


}

resource "aws_security_group" "my_webserver" { # Security group for web server
  name        = "WebServer Security Group"
  description = "My First SecurityGroup"

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

#--------------------------------------------------------------------------
# This code block creates classic load balancer
resource "aws_elb" "ws_balancer" {
  name               = "terraform-elb"
  availability_zones = data.aws_availability_zones.available.names


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
    command = "ansible-playbook playbook_deploy.yml"
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = [
    local_file.AnsibleInventory
  ]
}

resource "null_resource" "key_transfer_bastion" {

  provisioner "file" {
    source      = "${var.priv_key_path}"
    destination = "/home/ubuntu/.ssh/id_rsa"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${var.priv_key_path}")
      host        = aws_instance.bastion_host.public_ip
    }
  }

  #chmod key 400 on bastion

  provisioner "remote-exec" {
    inline = ["chmod 400 /home/ubuntu/.ssh/id_rsa"]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${var.priv_key_path}")
      host        = aws_instance.bastion_host.public_ip
    }
  }

}

# This code block provides instance info for Ansible inventory file
# 
resource "local_file" "AnsibleInventory" {
  content = templatefile("inventory.tmpl",
    {
      public-ip-bastion  = aws_instance.bastion_host.public_ip,
      public-dns-bastion = aws_instance.bastion_host.public_dns,
      sshkey             = "${var.priv_key_path}",
      private-dns        = aws_instance.ws_private_instance.*.private_dns,
      private-ip         = aws_instance.ws_private_instance.*.private_ip,
      private-id         = aws_instance.ws_private_instance.*.id
    }
  )
  filename        = "inventory"
  file_permission = "0600"
}