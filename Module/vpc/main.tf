provider "aws" {
  profile = "boto-int"
  region  = "${var.aws_region}"
}


data "aws_availability_zones" "available" {}

#creating VPC
resource "aws_vpc" "production-vpc" {
  cidr_block           = "${var.vpc_cidr}"
 # instance_tenancy     = "dedicated"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "production-vpc"
  }
}

#creating IGW and attaching to VPC
resource "aws_internet_gateway" "production-igw" {
  vpc_id = "${aws_vpc.production-vpc.id}"
  tags = {
    Name = "production-igw"
  }
}

#creating a public route table with route out to IGW
resource "aws_route_table" "public-route-table" {
  vpc_id = "${aws_vpc.production-vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.production-igw.id}"
  }
  tags = {
    Name = "public-route-table"
  }
}

#creating a private route table with route to nat gw
resource "aws_route_table" "private-route-table" {
  vpc_id = "${aws_vpc.production-vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.nat-gw.id}"
  }
  tags = {
    Name = "private-route-table"
  }
  depends_on     = ["aws_nat_gateway.nat-gw"]
}

#creating 3 public subnet
resource "aws_subnet" "public_subnet" {
  count                   = 3
  vpc_id                  = "${aws_vpc.production-vpc.id}"
  cidr_block              = "${var.public_cidrs[count.index]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  tags = {
    Name = "public_subnet.${count.index + 1}"
  }
}
#creating 3 private subnet
resource "aws_subnet" "private_subnet" {
  count             = 3
  vpc_id            = "${aws_vpc.production-vpc.id}"
  cidr_block        = "${var.private_cidrs[count.index]}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  tags = {
    Name = "private-subnet.${count.index + 1}"
  }
}

# Associate Public Subnet with Public Route Table
resource "aws_route_table_association" "public-route-table-association" {
  count          = 3
  subnet_id      = "${aws_subnet.public_subnet.*.id[count.index]}"
  route_table_id = "${aws_route_table.public-route-table.id}"
  depends_on     = ["aws_route_table.public-route-table", "aws_subnet.public_subnet"]
}

# Associate Private Subnet with rivate Route Table
resource "aws_route_table_association" "private-route-table-association" {
  count          = 3
  subnet_id      = "${aws_subnet.private_subnet.*.id[count.index]}"
  route_table_id = "${aws_route_table.private-route-table.id}"
  depends_on     = ["aws_route_table.private-route-table", "aws_subnet.private_subnet"]
}


##########nat gateway
#eip for nat gateway
resource "aws_eip" "eip-for-natgw" {
  vpc = true
  tags = {
    Name = "Production-EIP"
  }
}

#creating nat gateway
#there is a route need to be added to private subnet with nat gateway ID
resource "aws_nat_gateway" "nat-gw" {
  allocation_id = "${aws_eip.eip-for-natgw.id}"
  subnet_id     = "${aws_subnet.public_subnet.0.id}"
  tags = {
    Name = "production-nat-gw"
  }
  depends_on     = ["aws_eip.eip-for-natgw"]
}



