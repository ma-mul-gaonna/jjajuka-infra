# -- backend
resource "aws_ssm_parameter" "db_host" {
  name  = "/${var.app}/${var.env}/DB_HOST"
  type  = "String"
  value = module.database.host
}

resource "aws_ssm_parameter" "db_name" {
  name  = "/${var.app}/${var.env}/DB_NAME"
  type  = "String"
  value = var.app
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/${var.app}/${var.env}/DB_PASSWORD"
  type  = "SecureString"
  value = var.MYSQL_PASSWORD
}

resource "aws_ssm_parameter" "db_port" {
  name  = "/${var.app}/${var.env}/DB_PORT"
  type  = "String"
  value = tostring(var.database_port)
}

resource "aws_ssm_parameter" "db_username" {
  name  = "/${var.app}/${var.env}/DB_USERNAME"
  type  = "String"
  value = var.MYSQL_USER
}

resource "aws_ssm_parameter" "discord_webhook_url" {
  name  = "/${var.app}/${var.env}/DISCORD_WEBHOOK_URL"
  type  = "SecureString"
  value = var.discord_webhook_url
}

resource "aws_ssm_parameter" "ai_base_url" {
  name  = "/${var.app}/${var.env}/AI_BASE_URL"
  type  = "String"
  value = var.ai_base_url
}

# -- ai
resource "aws_ssm_parameter" "google_api_key" {
  name  = "/${var.app}/${var.env}/GOOGLE_API_KEY"
  type  = "SecureString"
  value = var.google_api_key
}
