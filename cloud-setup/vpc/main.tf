locals {
  create_vpc_resources = var.create_vpc
}

resource "aws_vpc" "main" {
  count = local.create_vpc_resources ? 1 : 0
  
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.environment}-vpc"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  count = local.create_vpc_resources ? 1 : 0
  
  vpc_id = aws_vpc.main[0].id

  tags = {
    Name = "${var.environment}-igw"
  }
}

# Create public subnets
resource "aws_subnet" "public" {
  count = local.create_vpc_resources ? length(var.availability_zones) : 0
  
  vpc_id            = aws_vpc.main[0].id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = var.availability_zones[count.index]
  
  # Enable auto-assign public IP for instances launched in these subnets
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-public-subnet-${count.index + 1}"
  }
}

# Create private subnets
resource "aws_subnet" "private" {
  count = local.create_vpc_resources ? length(var.availability_zones) : 0
  
  vpc_id            = aws_vpc.main[0].id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + length(var.availability_zones))
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.environment}-private-subnet-${count.index + 1}"
  }
}

# Create NAT Gateway for private subnets to access internet
resource "aws_eip" "nat" {
  count  = local.create_vpc_resources ? 1 : 0
  domain = "vpc"
  
  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "${var.environment}-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  count         = local.create_vpc_resources ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id
  
  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "${var.environment}-nat-gateway"
  }
}

# Create route table for public subnets
resource "aws_route_table" "public" {
  count  = local.create_vpc_resources ? 1 : 0
  vpc_id = aws_vpc.main[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw[0].id
  }

  tags = {
    Name = "${var.environment}-public-route-table"
  }
}

# Create route table for private subnets
resource "aws_route_table" "private" {
  count  = local.create_vpc_resources ? 1 : 0
  vpc_id = aws_vpc.main[0].id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[0].id
  }

  tags = {
    Name = "${var.environment}-private-route-table"
  }
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count          = local.create_vpc_resources ? length(aws_subnet.public) : 0
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

# Associate private subnets with private route table
resource "aws_route_table_association" "private" {
  count          = local.create_vpc_resources ? length(aws_subnet.private) : 0
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}

# Create VPC Endpoint for Lambda function to access AWS services without internet access
resource "aws_security_group" "vpc_endpoints" {
  count       = local.create_vpc_resources ? 1 : 0
  name        = "${var.environment}-vpc-endpoints-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.main[0].id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name = "${var.environment}-vpc-endpoints-sg"
  }
}

resource "aws_vpc_endpoint" "s3" {
  count             = local.create_vpc_resources ? 1 : 0
  vpc_id            = aws_vpc.main[0].id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private[0].id]

  tags = {
    Name = "${var.environment}-s3-endpoint"
  }
}

resource "aws_vpc_endpoint" "lambda" {
  count               = local.create_vpc_resources ? 1 : 0
  vpc_id              = aws_vpc.main[0].id
  service_name        = "com.amazonaws.${var.aws_region}.lambda"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = {
    Name = "${var.environment}-lambda-endpoint"
  }
}

resource "aws_vpc_endpoint" "cloudwatch" {
  count               = local.create_vpc_resources ? 1 : 0
  vpc_id              = aws_vpc.main[0].id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = {
    Name = "${var.environment}-cloudwatch-endpoint"
  }
}