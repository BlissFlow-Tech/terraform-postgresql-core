provider "postgresql" {
  host      = var.db_host
  port      = 5432
  username  = var.db_admin_username
  password  = var.db_admin_password
  sslmode   = "require"
  superuser = false
}

module "postgresql" {
  source = "../.."

  admin_role = var.db_admin_username

  roles = {
    app = {
      name     = "app"
      password = var.app_password
    }
  }

  databases = {
    app = {
      name  = "app"
      owner = "app"
    }
  }
}

output "databases" {
  value = module.postgresql.databases
}
