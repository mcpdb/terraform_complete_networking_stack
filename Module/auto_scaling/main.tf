provider "aws" {
  profile = "boto-int"
  region  = "${var.aws_region}"
}

#launch config for private instances
resource "aws_launch_configuration" "ec2-private-launch-config" {
  image_id        = "ami-0f7919c33c90f5b58"
  instance_type   = "t2.micro"
  security_groups = ["${aws_security_group.private-sg.id}"]
  key_name        = "${aws_key_pair.ec2keypair.id}"
  iam_instance_profile = "${var.iam_profile}"
  associate_public_ip_address = false

  user_data = <<-EOF
              #!/bin/bash
              yum -y install httpd
              export INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
              echo "<html><body><h1>Private Stack reporting from instance <b>"$INSTANCE_ID"</b></h1></body></html>" > /var/www/html/index.html
              service httpd start
              chkconfig httpd on
              EOF

  lifecycle {
    create_before_destroy = true
  }
}


#launch config for public instances
resource "aws_launch_configuration" "ec2-public-launch-config" {
  image_id        = "ami-0f7919c33c90f5b58"
  instance_type   = "t2.micro"
  security_groups = ["${aws_security_group.public-sg.id}"]
  key_name        = "${aws_key_pair.ec2keypair.id}"
  iam_instance_profile = "${var.iam_profile}"
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              yum -y install httpd
              export INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
              echo "<html><body><h1>Public Stack reporting from instance <b>"$INSTANCE_ID"</b></h1></body></html>" > /var/www/html/index.html
              service httpd start
              chkconfig httpd on
              EOF
  lifecycle {
    create_before_destroy = true
  }
}

#autoscaling for private ec2 instances
resource "aws_autoscaling_group" "ec2_private_auto_sg" {
  launch_configuration = "${aws_launch_configuration.ec2-private-launch-config.name}"
  vpc_zone_identifier  = "${var.private_subnet_ids}"
  target_group_arns    = ["${var.private-target_group_arn}"]
  health_check_type    = "ELB"
  name                 = "production-private-auto-sg"

  min_size = "${var.min_no_instance}"
  max_size = "${var.max_no_instance}"

  tag {
    key                 = "Name"
    value               = "Production-private-instance"
    propagate_at_launch = true
  }
}

#autoscaling for public ec2 instances
resource "aws_autoscaling_group" "ec2_public_auto_sg" {
  launch_configuration = "${aws_launch_configuration.ec2-public-launch-config.name}"
  vpc_zone_identifier  = "${var.public_subnet_ids}"
  target_group_arns    = ["${var.public-target_group_arn}"]
  health_check_type    = "ELB"
  name                 = "production-public-auto-sg"

  min_size = "${var.min_no_instance}"
  max_size = "${var.max_no_instance}"

  tag {
    key                 = "Name"
    value               = "Production-public-instance"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "public_auto_scaling_policy" {
  autoscaling_group_name    = "${aws_autoscaling_group.ec2_public_auto_sg.name}"
  name                      = "public_auto_scaling_policy"
  policy_type               = "TargetTrackingScaling"
  min_adjustment_magnitude  = 1

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 80.0
  }
}

resource "aws_autoscaling_policy" "private_auto_scaling_policy" {
  autoscaling_group_name    = "${aws_autoscaling_group.ec2_private_auto_sg.name}"
  name                      = "private_auto_scaling_policy"
  policy_type               = "TargetTrackingScaling"
  min_adjustment_magnitude  = 1

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 80.0
  }
}


resource "aws_key_pair" "ec2keypair" {
  key_name   = "ec2keypair"
  public_key = "${file(var.public_key)}"
}

###############
#creating a security group for public instance
resource "aws_security_group" "public-sg" {
  name   = "public-sg"
  vpc_id = "${var.vpc_id}"
}

#creating security group  rule for public instance
resource "aws_security_group_rule" "allow-ssh-pubsg" {
  from_port         = 22
  protocol          = "tcp"
  security_group_id = "${aws_security_group.public-sg.id}"
  to_port           = 22
  type              = "ingress"
  cidr_blocks       = ["103.15.250.0/24"]
}

resource "aws_security_group_rule" "allow-http-pubsg" {
  from_port         = 80
  protocol          = "tcp"
  security_group_id = "${aws_security_group.public-sg.id}"
  to_port           = 80
  type              = "ingress"
  cidr_blocks       = ["103.15.250.0/24"]
}

resource "aws_security_group_rule" "allow-alb-traffic" {
  from_port = 80
  protocol = "tcp"
  security_group_id = "${aws_security_group.public-sg.id}"
  to_port = 80
  type = "ingress"
  source_security_group_id = "${var.alb-sg-id}"
}

resource "aws_security_group_rule" "allow-outbound-pubsg" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.public-sg.id}"
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}



#creating a security group for private instance
resource "aws_security_group" "private-sg" {
  name   = "private-sg"
  vpc_id = "${var.vpc_id}"
  description = "only allow public sg group to access instances"
}

#creating security group  rule for private instance
resource "aws_security_group_rule" "allow-private-ssh" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.private-sg.id}"
  to_port           = 0
  type              = "ingress"
  #to enable all trafic from public ec2 instances
  source_security_group_id = "${aws_security_group.public-sg.id}"
}

resource "aws_security_group_rule" "allow-private-health-check" {
  from_port         = 80
  protocol          = "TCP"
  security_group_id = "${aws_security_group.private-sg.id}"
  to_port           = 80
  #cidr_blocks       = ["0.0.0.0/0"]
  source_security_group_id = "${var.alb-sg-id}"
  type              = "ingress"
  description       = "Allow heatlh checking for instances "
}
resource "aws_security_group_rule" "allow-private-outbound" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.private-sg.id}"
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}



