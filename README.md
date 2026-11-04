# terraform-postgresql-core

Terraform module that creates least-privilege login roles and the databases they own on a shared PostgreSQL server, with `PUBLIC` locked out of each database.

## Usage

```hcl
provider "postgresql" {
  host      = var.db_host
  port      = 5432
  username  = var.db_admin_username
  password  = var.db_admin_password
  sslmode   = "require"
  superuser = false
}

module "postgresql" {
  source  = "blissflow-tech/core/postgresql"
  version = "~> 1.0"

  admin_role = var.db_admin_username

  roles = {
    app = {
      name     = "app"
      password = var.app_password
    }
    monitoring = {
      name             = "monitoring"
      password         = var.monitoring_password
      connection_limit = 3
      grant_roles      = ["pg_read_all_stats"]
    }
  }

  databases = {
    app = {
      name  = "app"
      owner = "app"
    }
  }
}
```

## Notes

* The calling root configures the provider. On managed services where the admin is not a superuser (OCI Database with PostgreSQL, for one), set `superuser = false`: creating a database owned by another role needs a role-membership grant the provider only issues in that mode.
* `admin_role` is made a member of every database owner role, without the admin option. Without that membership the provider's database-level `REVOKE` silently does nothing and drifts on every plan. PostgreSQL 16+ rejects the admin option when member and grantor are the same role (`0LP01`), and a CREATEROLE admin already holds it implicitly, so the module ignores drift on `with_admin_option`.
* The owner's own privileges stay implicit. `postgresql_grant` revokes everything on destroy, so declaring the owner's `CONNECT` would lock every non-superuser out at teardown. The `removed` block for `postgresql_grant.owner_connect` lets states that once declared it forget it without revoking it.
* Memberships from `grant_roles` are separate `postgresql_grant_role` resources, so roles ignore drift on their own `roles` attribute. The connecting role needs the admin option on every role listed there.
* Databases depend on the owner membership, so it exists before a database is created and is revoked only after the database is dropped.
* Passwords are passed in. Keep them in a secret store, not in tfvars.

### Importing an existing database

A role and database created out of band must be imported before the first apply, or the apply fails with *already exists*:

```sh
terraform import 'module.postgresql.postgresql_role.this["app"]' app
terraform import 'module.postgresql.postgresql_database.this["app"]' app
```

Grants need no import, because `GRANT` and `REVOKE` are idempotent. Importing connects to the database, so run it from somewhere with a route to the server.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.9, < 2.0 |
| postgresql | ~> 1.25 |

## Providers

| Name | Version |
| ---- | ------- |
| postgresql | ~> 1.25 |

## Resources

| Name | Type |
| ---- | ---- |
| [postgresql_database.this](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/database) | resource |
| [postgresql_grant.public_revoked](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/grant) | resource |
| [postgresql_grant_role.admin_owner](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/grant_role) | resource |
| [postgresql_grant_role.member](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/grant_role) | resource |
| [postgresql_role.this](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/role) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| admin\_role | Login role the provider connects as. It is granted each database owner role so it can act as the owner when changing database-level privileges. | `string` | n/a | yes |
| databases | Databases to create, keyed by a stable identifier. Each one is owned by a role from roles. | <pre>map(object({<br/>    name             = string<br/>    owner            = string<br/>    revoke_public    = optional(bool, true)<br/>    connection_limit = optional(number, -1)<br/>  }))</pre> | `{}` | no |
| roles | Login roles to create, keyed by a stable identifier that databases reference as their owner. | <pre>map(object({<br/>    name             = string<br/>    password         = string<br/>    connection_limit = optional(number, -1)<br/>    grant_roles      = optional(list(string), [])<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| databases | The databases created, keyed by the input identifier |
| roles | The login roles created, keyed by the input identifier |
<!-- END_TF_DOCS -->

## License

Apache 2.0. See [LICENSE](LICENSE).
