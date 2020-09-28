// retrieve public key from sap landscape's Key vault
data "azurerm_key_vault_secret" "sid_pk" {
  count        = local.enable_auth_key ? 1 : 0
  name         = local.secret_sid_pk_name
  key_vault_id = local.kv_landscape_id
}

// Generate random password if password is set as authentication type and user doesn't specify a password, and save in KV
resource "random_password" "password" {
  count = (
    local.enable_auth_password
  && try(local.anydb.authentication.password, null) == null) ? 1 : 0
  length           = 16
  special          = true
  override_special = "_%@"
}

/*
 To force dependency between kv access policy and secrets. Expected behavior:
 https://github.com/terraform-providers/terraform-provider-azurerm/issues/4971
*/
// store the xdb logon username in KV
resource "azurerm_key_vault_secret" "auth_username" {
  depends_on   = [var.sid_kv_user_msi]
  count        = local.enable_auth_password ? 1 : 0
  name         = format("%s-%s-xdb-auth-username", local.prefix, local.sid)
  value        = local.sid_auth_username
  key_vault_id = local.sid_kv_user.id
}

// store the xdb logon password in KV
resource "azurerm_key_vault_secret" "auth_password" {
  depends_on   = [var.sid_kv_user_msi]
  count        = local.enable_auth_password ? 1 : 0
  name         = format("%s-%s-xdb-auth-password", local.prefix, local.sid)
  value        = local.sid_auth_password
  key_vault_id = local.sid_kv_user.id
}

// Generate random passwords as anydb database credentials
resource "random_password" "credentials" {
  count            = (local.enable_deployment && try(local.anydb_cred.db_systemdb_password, "") == "") ? 1 : 0
  length           = 16
  special          = true
  override_special = "_%@"
}

// Store Hana database credentials as secrets in KV
resource "azurerm_key_vault_secret" "db_systemdb" {
  count        = local.enable_deployment ? 1 : 0
  depends_on   = [var.sid_kv_user_msi]
  name         = format("%s-xdb-systemdb-password", local.prefix)
  value        = local.db_systemdb_password
  key_vault_id = local.sid_kv_user.id
}
