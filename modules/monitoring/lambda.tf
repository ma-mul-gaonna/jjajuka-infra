# -- RDS 스케줄러 Lambda 함수
data "archive_file" "rds_scheduler" {
  type        = "zip"
  source_file = "${path.module}/functions/rds_scheduler.py"
  output_path = "${path.module}/functions/rds_scheduler.zip"
}

resource "aws_lambda_function" "rds_scheduler" {
  function_name    = "${var.app}-${var.env}-rds-scheduler"
  role             = aws_iam_role.lambda_rds.arn
  runtime          = "python3.12"
  handler          = "rds_scheduler.handler"
  filename         = data.archive_file.rds_scheduler.output_path
  source_code_hash = data.archive_file.rds_scheduler.output_base64sha256

  environment {
    variables = {
      DB_IDENTIFIER = var.rds_identifier
    }
  }

  tags = {
    app     = var.app
    env     = var.env
    managed = "terraform"
  }
}

# -- EventBridge가 Lambda를 호출할 수 있도록 리소스 기반 권한 추가
resource "aws_lambda_permission" "rds_stop" {
  statement_id  = "AllowEventBridgeStop"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rds_scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rds_stop.arn
}

resource "aws_lambda_permission" "rds_start" {
  statement_id  = "AllowEventBridgeStart"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rds_scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rds_start.arn
}
