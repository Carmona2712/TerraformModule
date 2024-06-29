provider "aws" {
  region = "us-east-1"
}

# Creación de la VPC
resource "aws_vpc" "vpc_main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "mainVPC"
  }
}

# Creación de la subred pública 1
resource "aws_subnet" "public_subnet1" {
  vpc_id     = aws_vpc.vpc_main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "publicSubnet1"
  }
}

# Creación de la subred pública 2
resource "aws_subnet" "public_subnet2" {
  vpc_id     = aws_vpc.vpc_main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"  # Zona de disponibilidad B

  tags = {
    Name = "publicSubnet2"
  }
}

# Creación de la subred privada 1
resource "aws_subnet" "private_subnet1" {
  vpc_id     = aws_vpc.vpc_main.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1a"  # Zona de disponibilidad A

  tags = {
    Name = "privateSubnet1"
  }
}

# Creación de la subred privada 2
resource "aws_subnet" "private_subnet2" {
  vpc_id     = aws_vpc.vpc_main.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1b"  # Zona de disponibilidad B

  tags = {
    Name = "privateSubnet2"
  }
}

# Creación de Internet Gateway para las subredes públicas
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc_main.id

  tags = {
    Name = "mainIGW"
  }
}

# Asociación de Internet Gateway a la VPC y a las subredes públicas
resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.vpc_main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "publicRouteTable"
  }
}

resource "aws_route_table_association" "public_subnet1_association" {
  subnet_id      = aws_subnet.public_subnet1.id
  route_table_id = aws_route_table.public_route.id
}

resource "aws_route_table_association" "public_subnet2_association" {
  subnet_id      = aws_subnet.public_subnet2.id
  route_table_id = aws_route_table.public_route.id
}

# Definición del grupo de seguridad
resource "aws_security_group" "sec_group" {


  name        = "instance_sg"
  description = "Security group for EC2 instance"

  vpc_id = aws_vpc.vpc_main.id

  # Reglas de entrada
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Reglas de salida
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Definición de la instancia EC2
resource "aws_instance" "EC2_Instance_1" {
  ami           = "ami-04b70fa74e45c3917"  # ID de la AMI de Amazon Linux 2, por ejemplo
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet1.id

  vpc_security_group_ids = [
    aws_security_group.sec_group.id  # Asocia la instancia al grupo de seguridad definido arriba
  ]
  tags = {
    Name = "Ec2Instance"
  }
}

# Definición de la instancia EC2
resource "aws_instance" "EC2_Instance_2" {
  ami           = "ami-04b70fa74e45c3917"  # ID de la AMI de Amazon Linux 2, por ejemplo
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet2.id

  vpc_security_group_ids = [
    aws_security_group.sec_group.id  # Asocia la instancia al grupo de seguridad definido arriba
  ]
  tags = {
    Name = "Ec2Instance"
  }
}


