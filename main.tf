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
    Name = "WebServer"
  }
}

resource "aws_lb" "webserver_load_balancer" {
    name = "webserver-lb"
    internal = false
    load_balancer_type = "application"
    security_groups = [ aws_security_group.load_balancer_sg.id ]
    subnets = [ aws_subnet.public_subnet.id ]

    enable_deletion_protection = true

    access_logs {
      bucket = aws_s3_bucket.terraform_state.id
      prefix = "webserver-lb-access-log"
      enabled = true
    }

    tags = {
      Environment = "learning"
    }
}

resource "aws_lb_target_group" "webserver_target_group" {
  name = "lb-target-group"
  target_type = "alb"
  port = "80"
  protocol = "TCP"
  vpc_id = aws_vpc.main_vpc.id
}

resource "aws_lb_target_group_attachment" "webserver" {
  count = 2
  target_group_arn  = "${aws_lb_target_group.webserver_target_group.arn}"
  target_id         = "${aws_instance.webserver[count.index].id}"
  port              = "80"
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


