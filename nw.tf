resource "aws_vpc" "project_vpc" {
  cidr_block       = var.vpc_subnet
  instance_tenancy = "default"
  enable_dns_hostnames = true
  #enable_dns_support = true
  tags = {
    Name = "project_vpc"
  }
}

resource "aws_subnet" "pub_subnet" {
  count = local.count_avz

  vpc_id                  = aws_vpc.project_vpc.id
  cidr_block              = cidrsubnet(var.vpc_subnet, 8, count.index)
  availability_zone       = local.names_avz[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "sub-pub-${local.names_avz[count.index]}"
  }
}

resource "aws_subnet" "prv_subnet" {
  count                   = local.count_avz

  vpc_id                  = aws_vpc.project_vpc.id
  cidr_block              = cidrsubnet(var.vpc_subnet, 8, local.count_avz + count.index)
  availability_zone       = local.names_avz[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "sub-prv-${local.names_avz[count.index]}"
  }
}


resource "aws_internet_gateway" "inet_gw" {
  vpc_id = aws_vpc.project_vpc.id

  tags = {
    Name = "My_VPC_IGW"
  }
}

resource "aws_eip" "eip_nat" {
  count = local.count_avz

  vpc = true
  tags = {
    Name = "aws-eip-${local.names_avz[count.index]}"
  }
}

resource "aws_nat_gateway" "natgw_prv" {
  count = local.count_avz

  allocation_id = aws_eip.eip_nat[count.index].id
  subnet_id     = aws_subnet.pub_subnet[count.index].id

  tags = {
    Name = "nat-gw-${local.names_avz[count.index]}"
  }

  depends_on = [aws_internet_gateway.inet_gw, aws_instance.ws_private_instance]
}

resource "aws_route_table" "rt_pub" {
  vpc_id = aws_vpc.project_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.inet_gw.id
  }

  tags = {
    Name = "rt_pub"
  }
}

resource "aws_route_table_association" "rt_pub_associate" {
  count          = local.count_avz
  subnet_id      = aws_subnet.pub_subnet[count.index].id
  route_table_id = aws_route_table.rt_pub.id
}

resource "aws_route_table" "rt_prv" {
  count = local.count_avz

  vpc_id = aws_vpc.project_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw_prv[count.index].id
  }

  tags = {
    Name = "rt_prv-${local.names_avz[count.index]}"
  }
}

resource "aws_route_table_association" "rt_prv_associate" {
  count          = local.count_avz
  subnet_id      = aws_subnet.prv_subnet[count.index].id
  route_table_id = aws_route_table.rt_prv[count.index].id
}