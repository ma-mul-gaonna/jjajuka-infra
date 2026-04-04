locals {
  instances = {
    frontend = var.instance_ids.frontend
    app      = var.instance_ids.app
    ai       = var.instance_ids.ai
  }
}

# -- CPU 사용률 알람
resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
  for_each = local.instances

  alarm_name          = "${var.app}-${var.env}-${each.key}-cpu-high"
  alarm_description   = "${each.key} EC2 CPU 사용률 ${var.cpu_threshold}% 초과"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = var.cpu_threshold
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    InstanceId = each.value
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    app     = var.app
    env     = var.env
    managed = "terraform"
  }
}

# -- 인스턴스 상태 체크 알람
resource "aws_cloudwatch_metric_alarm" "ec2_status" {
  for_each = local.instances

  alarm_name          = "${var.app}-${var.env}-${each.key}-status-failed"
  alarm_description   = "${each.key} EC2 인스턴스 상태 이상"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"

  dimensions = {
    InstanceId = each.value
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    app     = var.app
    env     = var.env
    managed = "terraform"
  }
}
