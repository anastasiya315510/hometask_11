provider "aws" {
  region = "us-east-2"
}

# Get the default VPC
data "aws_vpc" "default" {
  default = true
}

# Security group for EC2
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow SSH, HTTP, and WordPress ports"
  vpc_id      = data.aws_vpc.default.id

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # WordPress exposed port
  ingress {
    description = "WordPress"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Get all subnets in the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# EC2 instance with user_data for Docker + WordPress
resource "aws_instance" "my_ec2" {
  ami                    = "ami-077b630ef539aa0b5" # Amazon Linux 2
  instance_type          = "t3.micro"
  key_name               = "hometask"
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name = "WordpressDockerInstance"
  }

  user_data = <<-EOF
              #!/bin/bash
              # Update system
              yum update -y

              # Install Docker
              amazon-linux-extras enable docker
              yum install -y docker
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user

              # Install Docker Compose
              curl -L "https://github.com/docker/compose/releases/download/v2.30.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose

              # Create docker-compose.yml
              cat <<EOL > /home/ec2-user/docker-compose.yml
              version: '3.3'
              services:
                db:
                  image: mysql:5.7
                  volumes:
                    - db_data:/var/lib/mysql
                  restart: always
                  environment:
                    MYSQL_ROOT_PASSWORD: somewordpress
                    MYSQL_DATABASE: wordpress
                    MYSQL_USER: wordpress
                    MYSQL_PASSWORD: wordpress
                wordpress:
                  depends_on:
                    - db
                  image: wordpress:latest
                  ports:
                    - "8000:80"
                  restart: always
                  environment:
                    WORDPRESS_DB_HOST: db:3306
                    WORDPRESS_DB_USER: wordpress
                    WORDPRESS_DB_PASSWORD: wordpress
                    WORDPRESS_DB_NAME: wordpress
              volumes:
                db_data: {}
              EOL

              # Run docker-compose
              cd /home/ec2-user
              docker-compose up -d
              EOF
}

# Output the public IP
output "ec2_public_ip" {
  value = aws_instance.my_ec2.public_ip
  description = "Public IP of the WordPress EC2 instance"
}
