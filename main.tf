terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

resource "aws_instance" "webserver" {
  count             = 2
  ami               = var.instance_ami
  instance_type     = var.instance_ec2_type
  security_groups   = [ aws_security_group.webserver_instances_sg ]
  user_data         = base64encode(<<-EOF
                    #!/bin/bash
                    yum update -y
                    yum install -y httpd
                    systemctl start httpd
                    systemctl enable httpd
                    echo "Hello from $(hostname)" > /var/www/html/index.html
                    EOF
  )
}

resource "aws_security_group" "webserver_instances_sg" {
  name = "webserver_instances_sg"
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [ load_balancer_web_security_group ]
  }
}

resource "aws_security_group" "load_balancer_sg" {
  name = "load_balancer_web_security_group"
  ingress = {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}


