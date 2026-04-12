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

# -- RDS Instance State-change Notification
resource "aws_cloudwatch_event_rule" "rds_state_change" {
  name        = "${var.app}-${var.env}-rds-state-change"
  description = "RDS 인스턴스 정지 / 시작 감지"

  event_pattern = jsonencode({
    source      = ["aws.rds"]
    detail-type = ["RDS DB Instance Event"]
    detail = {
      EventID          = ["RDS-EVENT-0087", "RDS-EVENT-0088"]
      SourceIdentifier = [var.rds_identifier]
    }
  })

  tags = {
    app     = var.app
    env     = var.env
    managed = "terraform"
  }
}

resource "aws_cloudwatch_event_target" "rds_state_sns" {
  rule = aws_cloudwatch_event_rule.rds_state_change.name
  arn  = aws_sns_topic.alerts.arn
}

# -- RDS 스케줄러 (Lambda)
resource "aws_cloudwatch_event_rule" "rds_stop" {
  name                = "${var.app}-${var.env}-rds-stop"
  description         = "KST 01:00 RDS 정지"
  schedule_expression = "cron(0 16 * * ? *)"

  tags = {
    app     = var.app
    env     = var.env
    managed = "terraform"
  }
}

resource "aws_cloudwatch_event_rule" "rds_start" {
  name                = "${var.app}-${var.env}-rds-start"
  description         = "KST 12:50 RDS 시작"
  schedule_expression = "cron(50 3 * * ? *)"

  tags = {
    app     = var.app
    env     = var.env
    managed = "terraform"
  }
}

resource "aws_cloudwatch_event_target" "rds_stop" {
  rule     = aws_cloudwatch_event_rule.rds_stop.name
  arn      = aws_lambda_function.rds_scheduler.arn
  role_arn = aws_iam_role.eventbridge_rds.arn

  input = jsonencode({ action = "stop" })
}

resource "aws_cloudwatch_event_target" "rds_start" {
  rule     = aws_cloudwatch_event_rule.rds_start.name
  arn      = aws_lambda_function.rds_scheduler.arn
  role_arn = aws_iam_role.eventbridge_rds.arn

  input = jsonencode({ action = "start" })
}
