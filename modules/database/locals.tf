locals {
  tags = {
    app     = var.app
    managed = "terraform"
    env     = var.env
    tier    = "database"
  }
  prefix      = "${var.app}-${var.env}"
  domain_name = "db.%{if var.env != "prod"}${var.env}.%{endif}${var.domain}"

  all_ips      = ["0.0.0.0/0"]
  all_protocol = "-1"
  tcp_protocol = "tcp"
}