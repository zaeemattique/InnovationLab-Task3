provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "Task3-vpc-zaeem" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Task3-vpc-zaeem"
  }
}

resource "aws_subnet" "Task3-publicSN-zaeem" {
  vpc_id            = aws_vpc.Task3-vpc-zaeem.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"

    tags = {
        Name = "Task3-publicSN-zaeem"
    }
}

resource "aws_subnet" "Task3-privateSN-zaeem" {
  vpc_id            = aws_vpc.Task3-vpc-zaeem.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2a" 

    tags = {
        Name = "Task3-privateSN-zaeem"
    }
}

resource "aws_internet_gateway" "Task3-igw-zaeem" {
  vpc_id = aws_vpc.Task3-vpc-zaeem.id  

    tags = {
        Name = "Task3-igw-zaeem"
    }
}

resource "aws_route_table" "Task3-publicRT-zaeem" {
  vpc_id = aws_vpc.Task3-vpc-zaeem.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Task3-igw-zaeem.id
  }

  tags = {
    Name = "Task3-publicRT-zaeem"
  }
}

resource "aws_route_table_association" "Task3-publicRTA-zaeem" {
  subnet_id      = aws_subnet.Task3-publicSN-zaeem.id
  route_table_id = aws_route_table.Task3-publicRT-zaeem.id
}

resource "aws_route_table" "Task3-privateRT-zaeem" {
  vpc_id = aws_vpc.Task3-vpc-zaeem.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.Task3-natgw-zaeem.id
  }

    tags = {
        Name = "Task3-privateRT-zaeem"
    }
}

resource "aws_route_table_association" "Task3-privateRTA-zaeem" {
  subnet_id      = aws_subnet.Task3-privateSN-zaeem.id
  route_table_id = aws_route_table.Task3-privateRT-zaeem.id
}

resource "aws_instance" "Task3-NginxPublic-zaeem" {
  ami           = "ami-04f9aa2b7c7091927"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.Task3-publicSN-zaeem.id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.Task3-PublicInstanceSG-zaeem.id]


  tags = {
    Name = "Task3-NginxPublic-zaeem"
  }

  user_data = <<-EOF
              #!/bin/bash
              sleep 30
              yum update -y
              yum install -y nginx
              systemctl start nginx
              systemctl enable nginx
              EOF
  
}

resource "aws_instance" "Task3-BackendPrivate1-zaeem" {
  ami           = "ami-04f9aa2b7c7091927"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.Task3-privateSN-zaeem.id
  vpc_security_group_ids = [aws_security_group.Task3-PrivateInstance1SG-zaeem.id]
  tags = {
    Name = "Task3-BackendPrivate1-zaeem"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "Hello from Backend Private Instance 1" > /var/www/html/index.html
              EOF
  
}

resource "aws_instance" "Task3-BackendPrivate2-zaeem" {
  ami           = "ami-04f9aa2b7c7091927"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.Task3-privateSN-zaeem.id
  vpc_security_group_ids = [aws_security_group.Task3-PrivateInstance2SG-zaeem.id]

  tags = {
    Name = "Task3-BackendPrivate2-zaeem"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "Hello from Backend Private Instance 2" > /var/www/html/index.html
              EOF
  
}

resource "aws_security_group" "Task3-PublicInstanceSG-zaeem" {
  name        = "Task3-PublicInstanceSG-zaeem"
  description = "Allow HTTP and SSH"
  vpc_id      = aws_vpc.Task3-vpc-zaeem.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "Task3-PrivateInstance1SG-zaeem" {
  name        = "Task3-PrivateInstance1SG-zaeem"
  description = "Allow HTTP from Public Subnet"
  vpc_id      = aws_vpc.Task3-vpc-zaeem.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.Task3-PublicInstanceSG-zaeem.id]
  }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
  
}

resource "aws_security_group" "Task3-PrivateInstance2SG-zaeem" {
  name        = "Task3-PrivateInstance2SG-zaeem"
  description = "Allow HTTP from Public Subnet"
  vpc_id      = aws_vpc.Task3-vpc-zaeem.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.Task3-PublicInstanceSG-zaeem.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
}

resource "aws_eip" "Task3-nat-eip-zaeem" {
  domain = "vpc"

  tags = {
    Name = "Task3-nat-eip-zaeem"
  }
  
}

resource "aws_nat_gateway" "Task3-natgw-zaeem" {
  allocation_id = aws_eip.Task3-nat-eip-zaeem.id
  subnet_id     = aws_subnet.Task3-publicSN-zaeem.id

  tags = {
    Name = "Task3-natgw-zaeem"
  }
  
}