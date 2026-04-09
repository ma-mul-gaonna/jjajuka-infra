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

# -- EC2 스케줄러 (SSM Automation)
resource "aws_cloudwatch_event_rule" "ec2_stop" {
  name                = "${var.app}-${var.env}-ec2-stop"
  description         = "KST 01:00 EC2 정지"
  schedule_expression = "cron(0 16 * * ? *)"

  tags = {
    app     = var.app
    env     = var.env
    managed = "terraform"
  }
}

resource "aws_cloudwatch_event_rule" "ec2_start" {
  name                = "${var.app}-${var.env}-ec2-start"
  description         = "KST 13:00 EC2 시작"
  schedule_expression = "cron(0 4 * * ? *)"

  tags = {
    app     = var.app
    env     = var.env
    managed = "terraform"
  }
}

resource "aws_cloudwatch_event_target" "ec2_stop" {
  rule     = aws_cloudwatch_event_rule.ec2_stop.name
  arn      = "arn:aws:ssm:ap-northeast-2::automation-definition/AWS-StopEC2Instance"
  role_arn = aws_iam_role.eventbridge_ec2.arn

  input = jsonencode({
    InstanceId = [
      var.instance_ids.frontend,
      var.instance_ids.app,
      var.instance_ids.ai,
    ]
  })
}

resource "aws_cloudwatch_event_target" "ec2_start" {
  rule     = aws_cloudwatch_event_rule.ec2_start.name
  arn      = "arn:aws:ssm:ap-northeast-2::automation-definition/AWS-StartEC2Instance"
  role_arn = aws_iam_role.eventbridge_ec2.arn

  input = jsonencode({
    InstanceId = [
      var.instance_ids.frontend,
      var.instance_ids.app,
      var.instance_ids.ai,
    ]
  })
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
