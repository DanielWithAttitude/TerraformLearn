variable "instance_ec2_type" {
  description = "ec2 instance type"
  type = string
  default = "t3.micro"
}

variable "instance_ami" {
  description = "ec2 instance id"
  type = string
  default = "ami-0dd574ef87b79ac6c"
}