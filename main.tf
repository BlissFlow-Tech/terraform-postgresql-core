locals {
  owners = toset([for d in var.databases : d.owner])

  memberships = merge([
    for key, r in var.roles : {
      for grant in r.grant_roles : "${key}/${grant}" => {
        role       = key
        grant_role = grant
      }
    }
  ]...)
}

resource "postgresql_role" "this" {
  for_each = var.roles

  name             = each.value.name
  login            = true
  password         = each.value.password
  connection_limit = each.value.connection_limit

  lifecycle {
    ignore_changes = [roles]
  }
}

resource "postgresql_grant_role" "member" {
  for_each = local.memberships

  role       = postgresql_role.this[each.value.role].name
  grant_role = each.value.grant_role
}

resource "postgresql_database" "this" {
  for_each = var.databases

  name             = each.value.name
  owner            = postgresql_role.this[each.value.owner].name
  connection_limit = each.value.connection_limit

  depends_on = [postgresql_grant_role.admin_owner]
}

resource "postgresql_grant_role" "admin_owner" {
  for_each = local.owners

  role              = var.admin_role
  grant_role        = postgresql_role.this[each.key].name
  with_admin_option = false

  lifecycle {
    ignore_changes = [with_admin_option]
  }
}

removed {
  from = postgresql_grant.owner_connect

  lifecycle {
    destroy = false
  }
}

resource "postgresql_grant" "public_revoked" {
  for_each = { for k, v in var.databases : k => v if v.revoke_public }

  database    = postgresql_database.this[each.key].name
  role        = "public"
  object_type = "database"
  privileges  = []

  depends_on = [postgresql_grant_role.admin_owner]
}
