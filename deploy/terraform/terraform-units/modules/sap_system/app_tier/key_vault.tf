// Generate random password if password is set as authentication type and user doesn't specify a password
resource "random_password" "password" {
  count = (
    local.enable_auth_password
  && try(var.application.authentication.password, null) == null) ? 1 : 0
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

// Store the app logon username in KV
resource "azurerm_key_vault_secret" "app_auth_username" {
  count        = local.enable_auth_password ? 1 : 0
  name         = format("%s-app-auth-username", local.prefix)
  value        = local.sid_auth_username
  key_vault_id = var.sid_kv_user_id
}

// Store the app logon username in KV when authentication type is password
resource "azurerm_key_vault_secret" "app_auth_password" {
  count        = local.enable_auth_password ? 1 : 0
  name         = format("%s-app-auth-password", local.prefix)
  value        = local.sid_auth_password
  key_vault_id = var.sid_kv_user_id
}
