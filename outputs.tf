output "databases" {
  description = "The databases created, keyed by the input identifier"
  value = {
    for k, d in postgresql_database.this :
    k => {
      name             = d.name
      owner            = d.owner
      connection_limit = d.connection_limit
    }
  }
}

output "roles" {
  description = "The login roles created, keyed by the input identifier"
  value = {
    for k, r in postgresql_role.this :
    k => {
      name = r.name
    }
  }
}
