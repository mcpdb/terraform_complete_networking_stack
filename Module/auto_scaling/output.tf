output "public-sg-id" {
  value = "${aws_security_group.public-sg.id}"
}


output "public_autoscaling_group" {
  value = "${aws_autoscaling_group.ec2_public_auto_sg.name}"
}



