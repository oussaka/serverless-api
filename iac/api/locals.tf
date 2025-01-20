locals {
  env             = terraform.workspace == "default" ? "dev" : terraform.workspace
  ddb_users_table = "Users${title(local.env)}"
}
