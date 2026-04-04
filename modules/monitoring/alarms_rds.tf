# -- RDS CPU 사용률 알람
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.app}-${var.env}-rds-cpu-high"
  alarm_description   = "RDS CPU 사용률 ${var.cpu_threshold}% 초과"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = var.cpu_threshold
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    DBInstanceIdentifier = var.rds_identifier
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    app     = var.app
    env     = var.env
    managed = "terraform"
  }
}

# -- RDS 스토리지 부족 알람
resource "aws_cloudwatch_metric_alarm" "rds_free_storage" {
  alarm_name          = "${var.app}-${var.env}-rds-storage-low"
  alarm_description   = "RDS 남은 스토리지 부족"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 1
  threshold           = var.rds_free_storage_threshold
  comparison_operator = "LessThanThreshold"

  dimensions = {
    DBInstanceIdentifier = var.rds_identifier
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    app     = var.app
    env     = var.env
    managed = "terraform"
  }
}

# -- RDS 연결 수 알람
resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "${var.app}-${var.env}-rds-connections-high"
  alarm_description   = "RDS DB 연결 수 ${var.rds_connections_threshold} 초과"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = var.rds_connections_threshold
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    DBInstanceIdentifier = var.rds_identifier
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    app     = var.app
    env     = var.env
    managed = "terraform"
  }
}
