provider "aws" {
  region = "us-east-1"
}
resource "aws_vpc" "development_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Development_VPC"
  }
}
resource "aws_internet_gateway" "IGW" {
  vpc_id = "${aws_vpc.development_vpc.id}"

  tags = {
    Name = "Development_IGW"
  }
}
resource "aws_route_table" "Route_Table" {
  vpc_id = "${aws_vpc.development_vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.IGW.id}"
  }

}
resource "aws_subnet" "public_subnet1" {
  cidr_block = "10.0.1.0/24"
  vpc_id = "${aws_vpc.development_vpc.id}"
  map_public_ip_on_launch = true
  tags = {
    Name = "Prod_Subnet"
  }
}
resource "aws_route_table_association" "rt_association" {
  route_table_id = "${aws_route_table.Route_Table.id}"
  subnet_id = "${aws_subnet.public_subnet1.id}"
}
# Creating security group
resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = "${aws_vpc.development_vpc.id}"
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Tomcat from anywhere"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH from my ip only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["173.48.205.16/32"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "prod_webserver_sg"
  }
}
resource "aws_network_interface" "prod_web_server_nic" {
  subnet_id = "${aws_subnet.public_subnet1.id}"
  private_ip = "10.0.1.50"
  security_groups = ["${aws_security_group.allow_tls.id}"]
}
resource "aws_instance" "web_server_instance" {
  ami = "ami-09d8b5222f2b93bf0"
  instance_type = "t2.micro"
  network_interface {
    device_index = 0
    network_interface_id = "${aws_network_interface.prod_web_server_nic.id}"
  }
   user_data = "${file("install_apache.sh")}"
}
