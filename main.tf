resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Cloud-Resume-VPC"
  }
}
# 1. The Subnet (This was missing or named differently)
resource "aws_subnet" "public_sub" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Cloud-Resume-Subnet"
  }
}

# 2. The Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Cloud-Resume-IGW"
  }
}

# 3. The Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Cloud-Resume-RT"
  }
}

# 4. The Association (Now this will work because public_sub is declared above)
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_sub.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # For production, you'd use your specific IP
  }
  ingress {
    description = "HTTP from everywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Cloud-Resume-SG"
  }
}
resource "aws_instance" "web_server" {
  ami           = "ami-0c101f26f147fa7fd" # Latest Amazon Linux 2023 in us-east-1
  instance_type = "t2.micro"

  subnet_id                   = aws_subnet.public_sub.id
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id]
  key_name                    = aws_key_pair.deployer.key_name
  associate_public_ip_address = true

  tags = {
    Name = "Cloud-Resume-EC2"
  }
}
output "instance_public_ip" {
  value = aws_instance.web_server.public_ip
}
resource "aws_key_pair" "deployer" {
  key_name   = "cloud-resume-key"
  public_key = file("./cloud-resume-key.pub")
}
