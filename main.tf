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
  count = 2
  ami = var.instance_ami
  instance_type = var.instance_ec2_type
  security_groups = [ aws_security_group.webserver_instances_sg ]
  user_data = <<-EOF
            #!/bin/bash
            echo "Hello, World!" > index.html
            python3 -m http.server 8080 &
            EOF
}

resource "aws_security_group" "webserver_instances_sg" {
  name = "webserver_instances_sg"
}

