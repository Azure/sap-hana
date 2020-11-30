/*
  Description:
  Set up key vault for sap library 
*/

// Create private KV with access policy
resource "azurerm_key_vault" "kv_prvt" {
  count                      = local.prvt_kv_exist ? 0 : 1
  name                       = local.prvt_kv_name
  location                   = local.region
  resource_group_name        = local.rg_exists ? data.azurerm_resource_group.library[0].name : azurerm_resource_group.library[0].name
  tenant_id                  = local.service_principal.tenant_id
  soft_delete_enabled        = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = true
  sku_name                   = "standard"

  access_policy {
    tenant_id = local.service_principal.tenant_id
    object_id = local.service_principal.object_id

    secret_permissions = [
      "get",
    ]
  }
}

// Create user KV with access policy
resource "azurerm_key_vault" "kv_user" {
  count                      = local.user_kv_exist ? 0 : 1
  name                       = local.user_kv_name
  location                   = local.region
  resource_group_name        = local.rg_exists ? data.azurerm_resource_group.library[0].name : azurerm_resource_group.library[0].name
  tenant_id                  = local.service_principal.tenant_id
  soft_delete_enabled        = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = true
  sku_name                   = "standard"

  access_policy {
    tenant_id = local.service_principal.tenant_id
    object_id = local.service_principal.object_id

    secret_permissions = [
      "delete",
      "get",
      "list",
      "set",
    ]
  }
}

/* Comment out code with users.object_id for the time being
resource "azurerm_key_vault_access_policy" "kv_user_portal" {
  count        = length(local.deployer_users_id)
  key_vault_id = azurerm_key_vault.kv_user.id
  tenant_id    = data.azurerm_client_config.deployer.tenant_id
  object_id    = local.deployer_users_id[count.index]

  secret_permissions = [
    "delete",
    "get",
    "list",
    "set",
  ]
}
*/

// Import an existing private Key Vault
data "azurerm_key_vault" "kv_prvt" {
  count               = local.prvt_kv_exist ? 1 : 0
  name                = local.prvt_kv_name
  resource_group_name = local.prvt_kv_rg_name
}

// Import an existing user Key Vault
data "azurerm_key_vault" "kv_user" {
  count               = local.user_kv_exist ? 1 : 0
  name                = local.user_kv_name
  resource_group_name = local.user_kv_rg_name
}
