

data "azurerm_key_vault_secret" "sid_username" {
  count        = local.enable_auth_password ? 1 : 0
  name         = local.sid_username_secret_name
  key_vault_id = local.kv_landscape_id
}

data "azurerm_key_vault_secret" "sid_password" {
  count        = local.enable_auth_password ? 1 : 0
  name         = local.sid_password_secret_name
  key_vault_id = local.kv_landscape_id
}

/*
 To force dependency between kv access policy and secrets. Expected behavior:
 https://github.com/terraform-providers/terraform-provider-azurerm/issues/4971
*/
// Store the xdb logon username in KV 
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
