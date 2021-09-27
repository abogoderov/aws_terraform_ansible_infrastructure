provider "aws" {
  region = "eu-central-1"

}
resource "tls_private_key" "bastion_host_key" {
  algorithm = "RSA"
  rsa_bits  = 4096

}

resource "aws_key_pair" "generated_key" {
  key_name   = "bastion_host_key"
  public_key = tls_private_key.bastion_host_key.public_key_openssh

}
resource "local_file" "private_key" {
  content  = tls_private_key.bastion_host_key.private_key_pem
  filename = "private_key.pem"
}

resource "aws_instance" "ws_private_instance" { # Creating 3 same private instances 
  count                  = 3
  ami                    = "ami-05f7491af5eef733a"
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.generated_key.key_name
  vpc_security_group_ids = [aws_security_group.my_webserver.id]
  tags = {
    Name = "Ngnix"
  }
}
resource "aws_instance" "bastion_host" { # Creating bastion host
  ami                    = "ami-05f7491af5eef733a"
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.generated_key.key_name
  vpc_security_group_ids = [aws_security_group.my_bastion.id]


  tags = {
    Name = "Bastion_host"
  }


}


locals { # Local variable to determine bastion host private ip
 cidr_bastion       = "${aws_instance.bastion_host.private_ip}/32"
# cidr_balancer      = "${aws_elb.ws_balancer.private_ip}/32"
  # depends_on = [aws_instance.bastion_host]
}

resource "aws_security_group" "my_webserver" { # Security group for web server
  name        = "WebServer Security Group"
  description = "My First SecurityGroup"

    ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    #cidr_blocks = ["${local.cidr_balancer}"]
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    #cidr_blocks = ["${local.cidr_balancer}"]
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
# This block creates classic load balancer
resource "aws_elb" "ws_balancer" {
  name               = "terraform-elb"
  availability_zones = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]


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

  instances                   = aws_instance.ws_private_instance.*.id
  #cross_zone_load_balancing   = true
  #idle_timeout                = 400
  #connection_draining         = true
  #connection_draining_timeout = 400
}
#--------------------------------------------------------------------------

output "BalancerDNS" {
  value = aws_elb.ws_balancer.dns_name
}
output "public_ip_bastion" {
  value = aws_instance.bastion_host.public_ip
}
resource "null_resource" "pre_provision" {
  provisioner "file" {
    source      = "./private_key.pem"
    destination = "~/.ssh/private_key.pem"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.bastion_host_key.private_key_pem
      host        = aws_instance.bastion_host.public_ip
    }
  }
  depends_on = [local_file.AnsibleInventory]
}

resource "null_resource" "provision" {
  provisioner "remote-exec" {
    inline = [
      "mkdir ~/ansible",
      "sudo apt update -y",
      "sudo apt install -y software-properties-common",
      "sudo add-apt-repository --yes --update ppa:ansible/ansible",
      "sudo apt install -y ansible",
      "sudo chmod 600 ~/.ssh/private_key.pem"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.bastion_host_key.private_key_pem
      host        = aws_instance.bastion_host.public_ip
    }
  }
  provisioner "file" {
    source      = "./ansible/"
    destination = "~/ansible"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.bastion_host_key.private_key_pem
      host        = aws_instance.bastion_host.public_ip
    }
  }

  provisioner "file" {
    source      = "./inventory"
    destination = "~/ansible/inventory"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.bastion_host_key.private_key_pem
      host        = aws_instance.bastion_host.public_ip
    }
  }

  depends_on = [null_resource.pre_provision]
}

resource "null_resource" "ansible_playbook"{
  provisioner "remote-exec" {
    inline = [
      "cd ~/ansible",
      "ansible-playbook playbook_deploy.yml"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.bastion_host_key.private_key_pem
      host        = aws_instance.bastion_host.public_ip
    }
  }
  depends_on =  [null_resource.provision]
}
