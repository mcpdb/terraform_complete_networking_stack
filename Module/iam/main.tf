provider "aws" {
  profile = "boto-int"
  region  = "${var.aws_region}"
}

#Step-1 create a iam role
#assume_role_policy — (Required) The policy that grants an entity permission to assume the role.
resource "aws_iam_role" "EC2_ROLE" {
  name = "EC2_ROLE"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["ec2.amazonaws.com","application-autoscaling.amazonaws.com"]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags = {
      Name = "EC2_ROLE"
  }
}

#step-2 create instance profile with the role created
#to link to an instance we need iam instance profile

resource "aws_iam_instance_profile" "ec2_iam_instance_profile" {
  name = "ec2_iam_instance_profile"
  role = "${aws_iam_role.EC2_ROLE.name}"
}

#step-3 Adding IAM polcies to role created
#To add IAM Policies which allows EC2 instance to execute specific commands for eg: access to S3 Bucket
resource "aws_iam_role_policy" "ec2_iam_role_policy" {
  name = "EC2-IAM-POLICY"
  role = "${aws_iam_role.EC2_ROLE.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:*",
        "elasticloadbalancing:*",
        "cloudwatch:*",
        "logs:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}



