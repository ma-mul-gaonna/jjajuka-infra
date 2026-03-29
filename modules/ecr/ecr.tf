resource "aws_ecr_repository" "this" {
  name = "${local.prefix}-ecr"

  tags = {
    app     = var.app
    env     = var.env
    managed = "terraform"
  }
}
