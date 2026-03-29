locals {
  tags = {
    app     = var.app
    managed = "terraform"
    env     = var.env
    tier    = "backend"
  }
  prefix       = "${var.app}-${var.env}"
  all_ips      = ["0.0.0.0/0"]
  all_protocol = "-1"
  tcp_protocol = "tcp"

}
