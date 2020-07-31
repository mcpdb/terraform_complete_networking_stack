output "alb-sg" {
  value = "${aws_security_group.alb-sg.id}"
}

output "private-alb_target_group_arn" {
  value = "${aws_lb_target_group.private-target-group.arn}"
}

output "public-alb_target_group_arn" {
  value = "${aws_lb_target_group.public-target-group.arn}"
}
