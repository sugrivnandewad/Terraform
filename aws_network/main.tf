provider "aws" {
  region = var.aws_region

}

terraform {
  backend "s3" {
    bucket = "terraform-sbn"
    key    = "dev/ec2/terraform.tfstate"
    region = "ap-south-1"

  }
}

resource "aws_vpc" "dev_vpc" {
  cidr_block = var.vpc_cidr_block
  tags       = var.tags

}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "dev_public_subnet" {
  for_each          = toset(data.aws_availability_zones.available.names)
  vpc_id            = aws_vpc.dev_vpc.id
  cidr_block        = element(var.public_subnet_cidr_blocks, index(data.aws_availability_zones.available.names, each.key))
  availability_zone = each.key

  tags = {
    Name        = "dev-public-subnet-${each.key}"
    Project     = "terraform-aws"
    Owner       = "DevOps Team"
    Environment = "Development"
  }
}

resource "aws_subnet" "dev_private_subnet" {
  for_each          = toset(data.aws_availability_zones.available.names)
  vpc_id            = aws_vpc.dev_vpc.id
  cidr_block        = element(var.private_subnet_cidr_blocks, index(data.aws_availability_zones.available.names, each.key))
  availability_zone = each.key
  tags = merge(
    var.tags,
    {
      Name = "dev-private-subnet-${each.key}"
    }
  )

  depends_on = [aws_subnet.dev_public_subnet] // Ensure public subnets are created first
}

resource "aws_internet_gateway" "dev_igw" {
  vpc_id = aws_vpc.dev_vpc.id // fixed reference
  tags = merge(
    var.tags,
    {
      Name = "dev-igw"
    }
  )

  lifecycle {
    create_before_destroy = true // Ensure the IGW is recreated if the VPC changes
  }
}

resource "aws_route_table" "dev_public_rt" {
  vpc_id = aws_vpc.dev_vpc.id
  tags = merge(
    var.tags,
    {
      Name = "dev-public-rt"
  })
  lifecycle {
    create_before_destroy = true // Ensure the route table is recreated if the VPC changes
  }
}

resource "aws_route" "dev_public_route" {
  route_table_id         = aws_route_table.dev_public_rt.id
  destination_cidr_block = var.destination_cidr_block
  gateway_id             = aws_internet_gateway.dev_igw.id

}

resource "aws_route_table_association" "dev_public_assoc" {
  for_each       = aws_subnet.dev_public_subnet
  subnet_id      = each.value.id
  route_table_id = aws_route_table.dev_public_rt.id
}


resource "aws_nat_gateway" "dev_ngw" {
  for_each = {
    for k, v in aws_subnet.dev_public_subnet :
    k => v if var.enable_nat_gateway && contains(keys(var.nat_gateway_allocation_ids), k)
  }
  allocation_id = var.nat_gateway_allocation_ids[each.key]
  subnet_id     = each.value.id
  depends_on    = [aws_internet_gateway.dev_igw]
  tags = merge(
    var.tags,
    {
      Name = "dev-ngw-${each.key}"
    }
  )
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_route_table" "dev_private_rt" {
  for_each = aws_subnet.dev_private_subnet
  vpc_id   = aws_vpc.dev_vpc.id
  tags = merge(
    var.tags,
    {
      Name = "dev-private-rt-${each.key}"
    }
  )
}

resource "aws_route" "dev_private_route" {
  for_each = {
    for k, v in aws_subnet.dev_private_subnet :
    k => v if contains(keys(aws_nat_gateway.dev_ngw), k)
  }
  route_table_id         = aws_route_table.dev_private_rt[each.key].id
  destination_cidr_block = var.destination_cidr_block
  nat_gateway_id         = aws_nat_gateway.dev_ngw[each.key].id
}

resource "aws_route_table_association" "dev_private_assoc" {
  for_each       = aws_subnet.dev_private_subnet
  subnet_id      = each.value.id
  route_table_id = aws_route_table.dev_private_rt[each.key].id

}
