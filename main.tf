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
  vpc_security_group_ids = [ aws_security_group.webserver_instances_sg.id ]
  subnet_id         = aws_subnet.public_subnet.id 
  user_data         = base64encode(<<-EOF
                    #!/bin/bash
                    yum update -y
                    yum install -y httpd
                    systemctl start httpd
                    systemctl enable httpd
                    echo "Hello from $(hostname)" > /var/www/html/index.html
                    EOF
  )
  tags = {
    Name = "WebServer + $(count.index)"
  }
}

resource "aws_security_group" "webserver_instances_sg" {
  name              = "webserver_instances_sg"
  vpc_id            = aws_vpc.main_vpc.id
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [ aws_security_group.load_balancer_sg.id ]
  }
}

resource "aws_security_group" "load_balancer_sg" {
  vpc_id            = aws_vpc.main_vpc.id
  name              = "load_balancer_web_security_group"
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}


