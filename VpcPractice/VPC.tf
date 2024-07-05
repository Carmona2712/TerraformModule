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

# Definición del grupo de seguridad para el balanceador de carga
resource "aws_lb_target_group" "target_group_app" {
  name     = "targetGroupApp"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc_main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 4
    interval            = 5
  }
}

# Definición del balanceador de carga
resource "aws_lb" "load_balancer_app" {
  name               = "loadBalancerApp"
  internal           = false  # Configúralo como "true" si deseas un ALB interno
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sec_group.id]
  subnets            = [aws_subnet.public_subnet1.id, aws_subnet.public_subnet2.id]

  tags = {
    Name = "load-balancer-app"
  }
}


# Definición de la instancia EC2
resource "aws_instance" "EC2_Instance_1" {
  ami           = "ami-04b70fa74e45c3917"  # ID de la AMI de Amazon Linux 2, por ejemplo
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet1.id
  associate_public_ip_address = true
  key_name = "MyWindowsKeyPair"  # Nombre de la clave SSH que se utilizará para conectarse a la instancia

  vpc_security_group_ids = [
    aws_security_group.sec_group.id  # Asocia la instancia al grupo de seguridad definido arriba
  ]
  tags = {
    Name = "Ec2Instance1"
  }

  depends_on = [aws_lb_target_group.target_group_app]

}

# Definición de la instancia EC2
resource "aws_instance" "EC2_Instance_2" {
  ami           = "ami-04b70fa74e45c3917"  # ID de la AMI de Amazon Linux 2, por ejemplo
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet2.id
  associate_public_ip_address = true
  key_name = "MyWindowsKeyPair2"  # Nombre de la clave SSH que se utilizará para conectarse a la instancia

  vpc_security_group_ids = [
    aws_security_group.sec_group.id  # Asocia la instancia al grupo de seguridad definido arriba
  ]
  tags = {
    Name = "Ec2Instance2"
  }

  depends_on = [aws_lb_target_group.target_group_app]

}

resource "aws_lb_target_group_attachment" "ec2_instance_1_attachment" {
  target_group_arn = aws_lb_target_group.target_group_app.arn
  target_id        = aws_instance.EC2_Instance_1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "ec2_instance_2_attachment" {
  target_group_arn = aws_lb_target_group.target_group_app.arn
  target_id        = aws_instance.EC2_Instance_2.id
  port             = 80
}

resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.load_balancer_app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group_app.arn
  }
}






