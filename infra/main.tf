terraform {
  backend "s3" {
     bucket         = "terraform-learn-tf-state-daniel" 
     key            = "state/locking/terraform.tfstate"
     region         = "eu-north-1"
     dynamodb_table = "terraform-locks"
     encrypt        = true
   }
}

provider "aws" {
  region = "eu-north-1"
}

resource "aws_s3_bucket_policy" "alb_log_policy" {
  bucket = var.log_bucket_name

  policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "logdelivery.elasticloadbalancing.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${var.log_bucket_name}/webserver-lb-access-log/AWSLogs/831645032308/*"
    }
  ]
})
}

resource "aws_instance" "webserver" {
  count             = 2
  ami               = var.instance_ami
  instance_type     = var.instance_ec2_type
  vpc_security_group_ids = [ aws_security_group.webserver_instances_sg.id ]
  subnet_id         = aws_subnet.public_subnet_az1.id
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
    subnets = [
        aws_subnet.public_subnet_az1.id,
        aws_subnet.public_subnet_az2.id
     ]

    enable_deletion_protection = false

    access_logs {
      bucket = var.log_bucket_name
      prefix = "webserver-lb-access-log"
      enabled = true
    }

    tags = {
      Environment = "learning"
    }
}

resource "aws_lb_target_group" "webserver_target_group" {
  name = "lb-target-group"
  target_type = "instance"
  port = "80"
  protocol = "HTTP"
  vpc_id = aws_vpc.main_vpc.id
}

resource "aws_lb_target_group_attachment" "webserver" {
  count = 2
  target_group_arn  = "${aws_lb_target_group.webserver_target_group.arn}"
  target_id         = "${aws_instance.webserver[count.index].id}"
  port              = "80"
}

resource "aws_lb_listener" "webserver_listener" {
  load_balancer_arn = aws_lb.webserver_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webserver_target_group.arn
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
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
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
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



