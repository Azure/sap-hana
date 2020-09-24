/*
  Description:
  Set up key vault for sap landscape
*/

data "azurerm_client_config" "deployer" {}

// Create private KV with access policy
resource "azurerm_key_vault" "kv_prvt" {
  name                       = local.kv_private_name
  location                   = local.region
  resource_group_name        = local.rg_exists ? data.azurerm_resource_group.resource-group[0].name : azurerm_resource_group.resource-group[0].name
  tenant_id                  = data.azurerm_client_config.deployer.tenant_id
  soft_delete_enabled        = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = true
  sku_name                   = "standard"
}

resource "azurerm_key_vault_access_policy" "kv_prvt_msi" {
  key_vault_id = azurerm_key_vault.kv_prvt.id

  tenant_id = data.azurerm_client_config.deployer.tenant_id
  object_id = var.deployer-uai.principal_id

  secret_permissions = [
    "get",
  ]
}

// Create user KV with access policy
resource "azurerm_key_vault" "kv_user" {
  name                       = local.kv_user_name
  location                   = local.region
  resource_group_name        = local.rg_exists ? data.azurerm_resource_group.resource-group[0].name : azurerm_resource_group.resource-group[0].name
  tenant_id                  = data.azurerm_client_config.deployer.tenant_id
  soft_delete_enabled        = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = true

  sku_name = "standard"
}

resource "azurerm_key_vault_access_policy" "kv_user_msi" {
  key_vault_id = azurerm_key_vault.kv_user.id
  tenant_id    = data.azurerm_client_config.deployer.tenant_id
  object_id    = var.deployer-uai.principal_id

  secret_permissions = [
    "delete",
    "get",
    "list",
    "set",
  ]
}

resource "azurerm_key_vault_access_policy" "kv_user_portal" {
  count        = length(local.kv_users)
  key_vault_id = azurerm_key_vault.kv_user.id
  tenant_id    = data.azurerm_client_config.deployer.tenant_id
  object_id    = local.kv_users[count.index]

  secret_permissions = [
    "delete",
    "get",
    "list",
    "set",
  ]
}

// Using TF tls to generate SSH key pair for iscsi devices and store in user KV
resource "tls_private_key" "iscsi" {
  count = (
    local.enable_iscsi_auth_key
  && try(file(var.sshkey.path_to_public_key), null) == null) ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "azurerm_key_vault_secret" "iscsi_ppk" {
  depends_on   = [azurerm_key_vault_access_policy.kv_user_msi]
  count        = local.enable_iscsi_auth_key ? 1 : 0
  name         = format("%s-iscsi-sshkey", local.prefix)
  value        = local.iscsi_private_key
  key_vault_id = azurerm_key_vault.kv_user.id
}

resource "azurerm_key_vault_secret" "iscsi_pk" {
  depends_on   = [azurerm_key_vault_access_policy.kv_user_msi]
  count        = local.enable_iscsi_auth_key ? 1 : 0
  name         = format("%s-iscsi-sshkey-pub", local.prefix)
  value        = local.iscsi_public_key
  key_vault_id = azurerm_key_vault.kv_user.id
}

/*
 To force dependency between kv access policy and secrets. Expected behavior:
 https://github.com/terraform-providers/terraform-provider-azurerm/issues/4971
*/
resource "azurerm_key_vault_secret" "iscsi_username" {
  depends_on   = [azurerm_key_vault_access_policy.kv_user_msi]
  count        = local.enable_iscsi_auth_password ? 1 : 0
  name         = format("%s-iscsi-username", local.prefix)
  value        = local.iscsi_auth_username
  key_vault_id = azurerm_key_vault.kv_user.id
}

resource "azurerm_key_vault_secret" "iscsi_password" {
  depends_on   = [azurerm_key_vault_access_policy.kv_user_msi]
  count        = local.enable_iscsi_auth_password ? 1 : 0
  name         = format("%s-iscsi-password", local.prefix)
  value        = local.iscsi_auth_password
  key_vault_id = azurerm_key_vault.kv_user.id
}

// Generate random password if password is set as authentication type and user doesn't specify a password, and save in KV
resource "random_password" "iscsi_password" {
  count = (
    local.enable_iscsi_auth_password
  && try(local.var_iscsi.authentication.password, null) == null) ? 1 : 0
  length           = 16
  special          = true
  override_special = "_%@"
}

// Using TF tls to generate SSH key pair for SID and store in user KV
resource "tls_private_key" "sid" {
  count     = try(file(var.sshkey.path_to_public_key), null) == null ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "azurerm_key_vault_secret" "sid_ppk" {
  depends_on   = [azurerm_key_vault_access_policy.kv_user_msi]
  name         = format("%s-sid-sshkey", local.prefix)
  value        = local.sid_private_key
  key_vault_id = azurerm_key_vault.kv_user.id
}

resource "azurerm_key_vault_secret" "sid_pk" {
  depends_on   = [azurerm_key_vault_access_policy.kv_user_msi]
  name         = format("%s-sid-sshkey-pub", local.prefix)
  value        = local.sid_public_key
  key_vault_id = azurerm_key_vault.kv_user.id
}

// random bytes to product
resource "random_id" "saplandscape" {
  byte_length = 4
}
