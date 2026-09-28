#create a resource block for a VPC with a CIDR block of 10.0.0.0/16
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  #Name the VPC "terraform-project-vpc"
  tags = {
    Name = "terraform-project-vpc"
  }
}
#creating private subnet in AZ 1
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  #Name of private subnet in AZ 1 "terraform-project-private-subnet-a"
  tags = {
    Name = "terraform-project-private-subnet-a"
  }
}
#creating private subnet in AZ 2
resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  #Name of private subnet in AZ 2 "terraform-project-private-subnet-b"
  tags = {
    Name = "terraform-project-private-subnet-b"
  }
}
#creating public subnet in AZ 1
resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "us-east-1a"
  #Name of public subnet in AZ 1 "terraform-project-public-subnet-a"
  tags = {
    Name = "terraform-project-public-subnet-a"
  }
}
#creating public subnet in AZ 2
resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "us-east-1b"
  #Name of public subnet in AZ 2 "terraform-project-public-subnet-b"
  tags = {
    Name = "terraform-project-public-subnet-b"
  }
}
#creating an internet gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  #Name of internet gateway "terraform-project-igw"
  tags = {
    Name = "terraform-project-igw"
  }
}
#creating public routing tables
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id
  #creating route to the internet
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "terrafrom-project-public-routing-table"
  }
}
#creating private routing table
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "terraform-project-private-routing-table"
  }
}
#create route table association for public a subnet
resource "aws_route_table_association" "public_a_association" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_route_table.id
}
#create route table association for public b subnet
resource "aws_route_table_association" "public_b_association" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_route_table.id
}
#create route table association for private a subnet
resource "aws_route_table_association" "private_a_association" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_route_table.id
}
#create route table association for private b subnet
resource "aws_route_table_association" "private_b_association" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_route_table.id
}
#create security group for alb
resource "aws_security_group" "alb_sg" {
  name        = "terraform-project-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id
  tags = {
    Name = "terraform-project-alb-sg"
  }
}
#create security group for ec2
resource "aws_security_group" "ec2_sg" {
  name        = "terraform-project-ec2-sg"
  description = "Security group for EC2"
  vpc_id      = aws_vpc.main.id
  tags = {
    Name = "terraform-project-ec2-sg"
  }
}
#create ingress rule to allow traffic from alb security group
resource "aws_vpc_security_group_ingress_rule" "ec2_sg_ingress" {
  security_group_id            = aws_security_group.ec2_sg.id
  referenced_security_group_id = aws_security_group.alb_sg.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}
#create ingress rule to allol traffic from the internet to the alb security group on port 443
resource "aws_vpc_security_group_ingress_rule" "alb_sg_ingress" {
  security_group_id = aws_security_group.alb_sg.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}
#create egress rule to allow traffic to the ec2 security group on port 80
resource "aws_vpc_security_group_egress_rule" "alb_sg_egress" {
  security_group_id            = aws_security_group.alb_sg.id
  referenced_security_group_id = aws_security_group.ec2_sg.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}
