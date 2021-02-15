
// Generate random password if password is set as authentication type and user doesn't specify a password, and save in KV
resource "random_password" "password" {
  count = (
    local.enable_auth_password
  && try(local.anydb.authentication.password, null) == null) ? 1 : 0

  length           = 32
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  special          = true
  override_special = "_%@"
}

/*
 To force dependency between kv access policy and secrets. Expected behavior:
 https://github.com/terraform-providers/terraform-provider-azurerm/issues/4971
*/
// Store the xdb logon username in KV when authentication type is password
resource "azurerm_key_vault_secret" "auth_username" {
  count        = local.enable_auth_password && local.use_local_credentials ? 1 : 0
  name         = format("%s-xdb-auth-username", local.prefix)
  value        = local.sid_auth_username
  key_vault_id = var.sid_kv_user_id
}

// Store the xdb logon password in KV when authentication type is password
resource "azurerm_key_vault_secret" "auth_password" {
  count        = local.enable_auth_password && local.use_local_credentials ? 1 : 0
  name         = format("%s-xdb-auth-password", local.prefix)
  value        = local.sid_auth_password
  key_vault_id = var.sid_kv_user_id
}
