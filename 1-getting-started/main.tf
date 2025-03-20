resource "aws_vpc" "poc_vpc" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "poc-vpc"
  }
}

resource "aws_subnet" "subnet_1" {
  vpc_id                  = aws_vpc.poc_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name   = "poc-subnet-1"
    Access = "Pubic"
  }
}

resource "aws_subnet" "subnet_2" {
  vpc_id                  = aws_vpc.poc_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name   = "poc-subnet-2"
    Access = "Private"
  }
}

resource "aws_subnet" "subnet_3" {
  vpc_id                  = aws_vpc.poc_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = false
  tags = {
    Name   = "poc-subnet-3"
    Access = "Private"
  }
}


# Attach an Internet Gateway to the VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.poc_vpc.id

  tags = {
    Name = "poc-igw"
  }
}

# Create a Public Route Table for subnet_1 and add a route to the internet via the internet gateway.
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.poc_vpc.id

  route {
    cidr_block = "0.0.0.0/0" # Route for all traffic
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "poc-public-rt"
  }
}

# Associate Public Subnet with Public Route Table
resource "aws_route_table_association" "public_assoc_1" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}



# Create a Private Route Table for subnet_2 with no route to the internet.
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.poc_vpc.id

  tags = {
    Name = "poc-private-rt"
  }
}


# Associate Private Subnet with Private Route Table
resource "aws_route_table_association" "private_assoc_2" {
  subnet_id      = aws_subnet.subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_assoc_3" {
  subnet_id      = aws_subnet.subnet_3.id
  route_table_id = aws_route_table.private_rt.id
}








# Create an Elastic IP for the NAT Gateway
resource "aws_eip" "nat_eip" {
  domain   = "vpc"
  tags = {
    Name = "poc-nat-eip"
  }
}

# Create a NAT Gateway in the public subnet
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.subnet_1.id
  tags = {
    Name = "poc-nat-gw"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}


# Add a route to the private route table for outbound internet access via the NAT Gateway
resource "aws_route" "private_nat_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
}


