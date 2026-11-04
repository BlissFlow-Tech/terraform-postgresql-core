variable "db_host" {
  description = "Hostname of the PostgreSQL server"
  type        = string
}

variable "db_admin_username" {
  description = "Admin login the provider connects as"
  type        = string
}

variable "db_admin_password" {
  description = "Password of the admin login"
  type        = string
  sensitive   = true
}

variable "app_password" {
  description = "Password for the app role"
  type        = string
  sensitive   = true
}
