provider "aws" {
  profile = "boto-int"
  region  = "${var.aws_region}"
}

resource "aws_sns_topic" "public-autoscaling-alert-topic" {
  name = "public-autoscaling-alert-topic"
  display_name = "public-autoscaling-alert-topic"

  delivery_policy = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultThrottlePolicy": {
      "maxReceivesPerSecond": 1
    }
  }
}
EOF
  provisioner "local-exec" {
    command = "aws sns subscribe --topic-arn ${self.arn} --protocol email --notification-endpoint ${var.email_target} --profile boto-int"
  }
}


resource "aws_autoscaling_notification" "public-autoscaling-notifcation" {
  group_names   = ["${var.public_autoscaling_group}"]
  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR"
  ]
  topic_arn     = "${aws_sns_topic.public-autoscaling-alert-topic.arn}"
}