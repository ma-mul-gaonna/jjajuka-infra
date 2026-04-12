# -- EC2 스케줄러 (EventBridge Scheduler → EC2 API)
resource "aws_scheduler_schedule" "ec2_stop" {
  name                         = "${var.app}-${var.env}-ec2-stop"
  schedule_expression          = "cron(0 1 * * ? *)"
  schedule_expression_timezone = "Asia/Seoul"
  state                        = "ENABLED"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:stopInstances"
    role_arn = aws_iam_role.scheduler_ec2.arn

    input = jsonencode({
      InstanceIds = [
        var.instance_ids.frontend,
        var.instance_ids.app,
        var.instance_ids.ai,
      ]
    })
  }
}

resource "aws_scheduler_schedule" "ec2_start" {
  name                         = "${var.app}-${var.env}-ec2-start"
  schedule_expression          = "cron(0 13 * * ? *)"
  schedule_expression_timezone = "Asia/Seoul"
  state                        = "ENABLED"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:startInstances"
    role_arn = aws_iam_role.scheduler_ec2.arn

    input = jsonencode({
      InstanceIds = [
        var.instance_ids.frontend,
        var.instance_ids.app,
        var.instance_ids.ai,
      ]
    })
  }
}
