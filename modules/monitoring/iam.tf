# -- EC2 스케줄러용 IAM Role (EventBridge Scheduler → EC2 API)
resource "aws_iam_role" "scheduler_ec2" {
  name = "${var.app}-${var.env}-scheduler-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    app     = var.app
    env     = var.env
    managed = "terraform"
  }
}

resource "aws_iam_role_policy" "scheduler_ec2" {
  name = "${var.app}-${var.env}-scheduler-ec2-policy"
  role = aws_iam_role.scheduler_ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:StopInstances",
          "ec2:StartInstances"
        ]
        Resource = "arn:aws:ec2:ap-northeast-2:*:instance/*"
      }
    ]
  })
}

# -- RDS 스케줄러용 IAM Role (EventBridge → Lambda)
resource "aws_iam_role" "eventbridge_rds" {
  name = "${var.app}-${var.env}-eventbridge-rds-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    app     = var.app
    env     = var.env
    managed = "terraform"
  }
}

resource "aws_iam_role_policy" "eventbridge_rds" {
  name = "${var.app}-${var.env}-eventbridge-rds-policy"
  role = aws_iam_role.eventbridge_rds.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # EventBridge가 RDS Lambda 함수를 호출할 수 있도록 허용
        Effect   = "Allow"
        Action   = "lambda:InvokeFunction"
        Resource = aws_lambda_function.rds_scheduler.arn
      }
    ]
  })
}

# -- RDS 스케줄러용 Lambda IAM Role (Lambda → RDS 정지/시작)
resource "aws_iam_role" "lambda_rds" {
  name = "${var.app}-${var.env}-lambda-rds-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    app     = var.app
    env     = var.env
    managed = "terraform"
  }
}

resource "aws_iam_role_policy" "lambda_rds" {
  name = "${var.app}-${var.env}-lambda-rds-policy"
  role = aws_iam_role.lambda_rds.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds:StopDBInstance",
          "rds:StartDBInstance"
        ]
        Resource = "arn:aws:rds:ap-northeast-2:*:db:${var.app}-${var.env}*"
      },
      {
        # Lambda 기본 로그 권한
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}
