
/*
  Description:
  Set up key vault for sap system
*/

// Create private KV with access policy
resource "azurerm_key_vault" "sid_kv_prvt" {
  count                      = local.enable_sid_deployment ? 1 : 0
  name                       = local.sid_kv_private_name
  location                   = local.region
  resource_group_name        = local.rg_exists ? data.azurerm_resource_group.resource-group[0].name : azurerm_resource_group.resource-group[0].name
  tenant_id                  = local.spn.tenant_id
  soft_delete_enabled        = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = true
  sku_name                   = "standard"
}

resource "azurerm_key_vault_access_policy" "sid_kv_prvt_spn" {
  count        = local.enable_sid_deployment ? 1 : 0
  key_vault_id = azurerm_key_vault.sid_kv_prvt[0].id
  tenant_id    = local.spn.tenant_id
  object_id    = local.spn.client_id
  secret_permissions = [
    "get",
  ]
}

// Create user KV with access policy
resource "azurerm_key_vault" "sid_kv_user" {
  count                      = local.enable_sid_deployment ? 1 : 0
  name                       = local.sid_kv_user_name
  location                   = local.region
  resource_group_name        = local.rg_exists ? data.azurerm_resource_group.resource-group[0].name : azurerm_resource_group.resource-group[0].name
  tenant_id                  = local.spn.tenant_id
  soft_delete_enabled        = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = true
  sku_name                   = "standard"
}

resource "azurerm_key_vault_access_policy" "sid_kv_user_spn" {
  count        = local.enable_sid_deployment ? 1 : 0
  key_vault_id = azurerm_key_vault.sid_kv_user[0].id
  tenant_id    = local.spn.tenant_id
  object_id    = local.spn.client_id
  secret_permissions = [
    "delete",
    "get",
    "list",
    "set",
  ]
}

/* Comment out code with users.object_id for the time being
resource "azurerm_key_vault_access_policy" "sid_kv_user_portal" {
  count        = local.enable_sid_deployment ? length(local.kv_users) : 0
  key_vault_id = azurerm_key_vault.sid_kv_user[0].id
  tenant_id    = data.azurerm_client_config.deployer.tenant_id
  object_id    = local.kv_users[count.index]

  secret_permissions = [
    "delete",
    "get",
    "list",
    "set",
  ]
}
*/
// random bytes to product
resource "random_id" "sapsystem" {
  byte_length = 4
}
