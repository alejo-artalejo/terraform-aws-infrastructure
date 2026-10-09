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
#create iam role for ec2 instance and its Trust Policy
resource "aws_iam_role" "ec2_role" {
  name = "terraform-project-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  tags = {
    Name = "terraform-project-ec2-role"
  }
}
#attach the AmazonSSMManagedInstanceCore policy to the ec2 role
resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  #attach to the ec2 role
  role = aws_iam_role.ec2_role.name
  #attach the AmazonSSMManagedInstanceCore policy
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
#create an instance profile for the ec2 role
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "terraform-project-ec2-instance-profile"
  #attach the ec2 role to the instance profile
  role = aws_iam_role.ec2_role.name
}
#call lastest amazon linux 3 ami from ssm parameter store
data "aws_ssm_parameter" "ami_parameter" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}
#create ec2 instance template
resource "aws_launch_template" "ec2_template" {
  name_prefix   = "terraform-project-ec2-app_template"
  image_id      = data.aws_ssm_parameter.ami_parameter.value # Amazon Linux 3 AMI
  instance_type = "t3.micro"
  #attach the instance profile to the ec2 instance
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }
  #associate the ec2 instance with the private subnet and security group
  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.ec2_sg.id]
  }
  #add user data to install nginx and create a simple html page
  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y nginx
    systemctl start nginx
    systemctl enable nginx
    echo "<h1>Welcome to Terraform Project</h1>" > /usr/share/nginx/
    
    html/index.html
    EOF
  )
  tags = {
    Name = "terraform-project-ec2-app-template"
  }
}
#create and configure application load balancer
resource "aws_lb" "alb" {
  name               = "terraform-project-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]
}
#request CNAME from ACM for the ALB certificate
resource "aws_acm_certificate" "alb_cert" {
  domain_name       = "app.artalejolabs.com"
  validation_method = "DNS"
}
#create ALB target group to EC2
resource "aws_lb_target_group" "alb_target_group" {
  name     = "terraform-project-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  #configure ec2 health checks
  health_check {
    protocol = "HTTP"
    port     = "traffic-port"
    path     = "/"
    matcher  = "200"
  }
}
#create ALB listener with the ACM certificate
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.alb_cert.arn
  #default action to forward traffic to the target group
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }
}
