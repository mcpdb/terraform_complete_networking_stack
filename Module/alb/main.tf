
provider "aws" {
  profile = "boto-int"
  region  = "${var.aws_region}"
}

#Creating public ALB
resource "aws_lb" "public-load-balancer" {
  name     = "public-load-balancer"
  internal = false

  security_groups = [
    "${aws_security_group.alb-sg.id}",
  ]

  subnets = [
    "${var.pub-subnet1}",
    "${var.pub-subnet2}",
    "${var.pub-subnet3}"
  ]

  tags = {
    Name = "public-load-balancer"
  }

  ip_address_type    = "ipv4"
  load_balancer_type = "application"
}

#creating a public target group
resource "aws_lb_target_group" "public-target-group" {
  health_check {
    interval            = 10
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }

  name        = "public-terraform-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = "${var.vpc_id}"
}

#listner for public load balancer
resource "aws_lb_listener" "public-alb-listner" {
  load_balancer_arn = "${aws_lb.public-load-balancer.arn}"
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.public-target-group.arn}"
  }
}

###############

#Creating private ALB
resource "aws_lb" "private-load-balancer" {
  name     = "private-load-balancer"
  internal = true

  security_groups = [
    "${aws_security_group.alb-sg.id}",
  ]

  subnets = [
    "${var.pri-subnet1}",
    "${var.pri-subnet2}",
    "${var.pri-subnet3}"
  ]

  tags = {
    Name = "private_load_balancer"
  }

  ip_address_type    = "ipv4"
  load_balancer_type = "application"
}

resource "aws_lb_target_group" "private-target-group" {
  health_check {
    interval            = 10
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }

  name        = "private-terraform-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = "${var.vpc_id}"
}

#listner for private load balancer
resource "aws_lb_listener" "private-alb-listner" {
  load_balancer_arn = "${aws_lb.private-load-balancer.arn}"
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.private-target-group.arn}"
  }
}

#please enote that we need a route in EC2 SG from below ALB security group to accept http traffic from ALB to EC2
#So the rule is updated on autoscaling  module where we have created SG for EC2
resource "aws_security_group" "alb-sg" {
  name   = "alb-sg"
  vpc_id = "${var.vpc_id}"
  description= "ALB security group"
}

resource "aws_security_group_rule" "inbound_http" {
  from_port         = 80
  protocol          = "tcp"
  security_group_id = "${aws_security_group.alb-sg.id}"
  to_port           = 80
  type              = "ingress"
  cidr_blocks       = ["103.15.250.0/24"]
  description       = "allow web traffic to loadbalancer"
}

resource "aws_security_group_rule" "inbound_private_subnts" {
  from_port         = 80
  protocol          = "tcp"
  security_group_id = "${aws_security_group.alb-sg.id}"
  to_port                = 80
  type                    = "ingress"
  source_security_group_id = "${var.public-sg-id}"
  description       = "if you want public instance to access private loadbancer this rule is needed"
}

resource "aws_security_group_rule" "outbound_all" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.alb-sg.id}"
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}
