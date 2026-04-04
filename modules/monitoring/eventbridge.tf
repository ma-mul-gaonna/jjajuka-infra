# -- EC2 Instance State-change Notification
resource "aws_cloudwatch_event_rule" "ec2_state_change" {
  name        = "${var.app}-${var.env}-ec2-state-change"
  description = "EC2 인스턴스 stopped / terminated 감지"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance State-change Notification"]
    detail = {
      state = ["stopped", "terminated"]
      instance-id = [
        var.instance_ids.frontend,
        var.instance_ids.app,
        var.instance_ids.ai,
      ]
    }
  })

  tags = {
    app     = var.app
    env     = var.env
    managed = "terraform"
  }
}

resource "aws_cloudwatch_event_target" "ec2_state_sns" {
  rule = aws_cloudwatch_event_rule.ec2_state_change.name
  arn  = aws_sns_topic.alerts.arn
}
