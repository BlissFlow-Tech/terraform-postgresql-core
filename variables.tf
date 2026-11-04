variable "admin_role" {
  description = "Login role the provider connects as. It is granted each database owner role so it can act as the owner when changing database-level privileges."
  type        = string
}

variable "roles" {
  description = "Login roles to create, keyed by a stable identifier that databases reference as their owner."
  type = map(object({
    name             = string
    password         = string
    connection_limit = optional(number, -1)
    grant_roles      = optional(list(string), [])
  }))
  default = {}
}

variable "databases" {
  description = "Databases to create, keyed by a stable identifier. Each one is owned by a role from roles."
  type = map(object({
    name             = string
    owner            = string
    revoke_public    = optional(bool, true)
    connection_limit = optional(number, -1)
  }))
  default = {}

  validation {
    condition     = alltrue([for d in var.databases : contains(keys(var.roles), d.owner)])
    error_message = "Every database owner must be a key of roles."
  }
}
