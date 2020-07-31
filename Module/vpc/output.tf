output "aws_vpc_id" {
  value = "${aws_vpc.production-vpc.id}"
}

output "pub_subnets" {
  value = "${aws_subnet.public_subnet.*.id}"
}

output "pri_subnets" {
  value = "${aws_subnet.private_subnet.*.id}"
}

#public subnet1
output "pub-subnet1" {
  value = "${element(aws_subnet.public_subnet.*.id,1)}"
}

#public subnet2
output "pub-subnet2" {
  value = "${element(aws_subnet.public_subnet.*.id,2)}"
}

#public subnet3
output "pub-subnet3" {
  value = "${element(aws_subnet.public_subnet.*.id,3)}"
}

#private subnet1
output "pri-subnet1" {
  value = "${element(aws_subnet.private_subnet.*.id,1)}"
}

#private subnet2
output "pri-subnet2" {
  value = "${element(aws_subnet.private_subnet.*.id,2)}"
}

#private subnet3
output "pri-subnet3" {
  value = "${element(aws_subnet.private_subnet.*.id,3)}"
}
