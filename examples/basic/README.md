# Basic example

Creates an `app` login role and an `app` database it owns, with `PUBLIC` revoked from the database.

```sh
terraform init
terraform apply \
  -var db_host=<host> \
  -var db_admin_username=<admin> \
  -var db_admin_password=<admin-password> \
  -var app_password=<app-password>
```
