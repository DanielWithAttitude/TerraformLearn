resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  depends_on = [ 
    aws_lb.webserver_load_balancer,
    aws_instance.webserver
   ]
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "az1_assoc" {
  subnet_id      = aws_subnet.public_subnet_az1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "az2_assoc" {
  subnet_id      = aws_subnet.public_subnet_az2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_subnet" "public_subnet_az1" {
  vpc_id                    = aws_vpc.main_vpc.id
  cidr_block                = "10.0.3.0/24"
  map_public_ip_on_launch   = true
  availability_zone = "eu-north-1a"
}

resource "aws_subnet" "public_subnet_az2" {
  vpc_id                    = aws_vpc.main_vpc.id
  cidr_block                = "10.0.2.0/24"
  map_public_ip_on_launch   = true
  availability_zone = "eu-north-1b"
}