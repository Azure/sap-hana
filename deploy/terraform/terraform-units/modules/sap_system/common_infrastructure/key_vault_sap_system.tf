
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
  tenant_id                  = data.azurerm_client_config.deployer.tenant_id
  soft_delete_enabled        = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = true
  sku_name                   = "standard"
}

resource "azurerm_key_vault_access_policy" "sid_kv_prvt_msi" {
  count        = local.enable_sid_deployment ? 1 : 0
  key_vault_id = azurerm_key_vault.sid_kv_prvt[0].id

  tenant_id = data.azurerm_client_config.deployer.tenant_id
  object_id = var.deployer-uai.principal_id

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
  tenant_id                  = data.azurerm_client_config.deployer.tenant_id
  soft_delete_enabled        = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = true

  sku_name = "standard"
}

resource "azurerm_key_vault_access_policy" "sid_kv_user_msi" {
  count        = local.enable_sid_deployment ? 1 : 0
  key_vault_id = azurerm_key_vault.sid_kv_user[0].id
  tenant_id    = data.azurerm_client_config.deployer.tenant_id
  object_id    = var.deployer-uai.principal_id

  secret_permissions = [
    "delete",
    "get",
    "list",
    "set",
  ]
}

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

// Generate random password if password is set as authentication type and user doesn't specify a password, and save in KV
resource "random_password" "hdb_password" {
  count = (
    local.enable_hdb_auth_password
  && try(local.hdb.authentication.password, null) == null) ? 1 : 0
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "random_password" "app_password" {
  count = (
    local.enable_app_auth_password
  && try(var.application.authentication.password, null) == null) ? 1 : 0
  length           = 16
  special          = true
  override_special = "_%@"
}

// random bytes to product
resource "random_id" "sapsystem" {
  byte_length = 4
}

/*
 To force dependency between kv access policy and secrets. Expected behavior:
 https://github.com/terraform-providers/terraform-provider-azurerm/issues/4971
*/
// store the hdb logon username in KV
resource "azurerm_key_vault_secret" "hdb_auth_username" {
  depends_on   = [azurerm_key_vault_access_policy.sid_kv_user_msi]
  count        = local.enable_hdb_auth_password ? 1 : 0
  name         = format("%s-%s-hdb-auth-username", local.prefix, local.sid)
  value        = local.hdb_auth_username
  key_vault_id = azurerm_key_vault.sid_kv_user[0].id
}

// store the app logon username in KV
resource "azurerm_key_vault_secret" "app_auth_username" {
  depends_on   = [azurerm_key_vault_access_policy.sid_kv_user_msi]
  count        = local.enable_app_auth_password ? 1 : 0
  name         = format("%s-%s-app-auth-username", local.prefix, local.sid)
  value        = local.app_auth_username
  key_vault_id = azurerm_key_vault.sid_kv_user[0].id
}

// store the hdb logon password in KV
resource "azurerm_key_vault_secret" "hdb_auth_password" {
  depends_on   = [azurerm_key_vault_access_policy.sid_kv_user_msi]
  count        = local.enable_hdb_auth_password ? 1 : 0
  name         = format("%s-%s-hdb-auth-password", local.prefix, local.sid)
  value        = local.hdb_auth_password
  key_vault_id = azurerm_key_vault.sid_kv_user[0].id
}

// store the app logon password in KV
resource "azurerm_key_vault_secret" "app_auth_password" {
  depends_on   = [azurerm_key_vault_access_policy.sid_kv_user_msi]
  count        = local.enable_app_auth_password ? 1 : 0
  name         = format("%s-%s-app-auth-password", local.prefix, local.sid)
  value        = local.app_auth_password
  key_vault_id = azurerm_key_vault.sid_kv_user[0].id
}


// Generate random passwords as hana database credentials
/* TODO: passwords generating enhancement. 
   Currently, six passwords for hana database credentials are generated regardless of how many passwords populated in credentials block. 
   If some of them is empty, one of these pre-generated passwords with a fixed index will be used.
*/
resource "random_password" "credentials" {
  count            = local.enable_hdb_deployment ? 6 : 0
  length           = 16
  special          = true
  override_special = "_%@"
}

// Store Hana database credentials as secrets in KV
resource "azurerm_key_vault_secret" "db_systemdb" {
  count        = local.enable_hdb_deployment ? 1 : 0
  depends_on   = [azurerm_key_vault_access_policy.sid_kv_user_msi]
  name         = format("%s-db-systemdb-password", local.prefix)
  value        = local.db_systemdb_password
  key_vault_id = azurerm_key_vault.sid_kv_user[0].id
}

resource "azurerm_key_vault_secret" "os_sidadm" {
  count        = local.enable_hdb_deployment ? 1 : 0
  depends_on   = [azurerm_key_vault_access_policy.sid_kv_user_msi]
  name         = format("%s-os-sidadm-password", local.prefix)
  value        = local.os_sidadm_password
  key_vault_id = azurerm_key_vault.sid_kv_user[0].id
}

resource "azurerm_key_vault_secret" "os_sapadm" {
  count        = local.enable_hdb_deployment ? 1 : 0
  depends_on   = [azurerm_key_vault_access_policy.sid_kv_user_msi]
  name         = format("%s-os-sapadm-password", local.prefix)
  value        = local.os_sapadm_password
  key_vault_id = azurerm_key_vault.sid_kv_user[0].id
}

resource "azurerm_key_vault_secret" "xsa_admin" {
  count        = local.enable_hdb_deployment ? 1 : 0
  depends_on   = [azurerm_key_vault_access_policy.sid_kv_user_msi]
  name         = format("%s-xsa-admin-password", local.prefix)
  value        = local.xsa_admin_password
  key_vault_id = azurerm_key_vault.sid_kv_user[0].id
}

resource "azurerm_key_vault_secret" "cockpit_admin" {
  count        = local.enable_hdb_deployment ? 1 : 0
  depends_on   = [azurerm_key_vault_access_policy.sid_kv_user_msi]
  name         = format("%s-cockpit-admin-password", local.prefix)
  value        = local.cockpit_admin_password
  key_vault_id = azurerm_key_vault.sid_kv_user[0].id
}

resource "azurerm_key_vault_secret" "ha_cluster" {
  count        = local.enable_hdb_deployment && local.hdb_ha ? 1 : 0
  depends_on   = [azurerm_key_vault_access_policy.sid_kv_user_msi]
  name         = format("%s-ha-cluster-password", local.prefix)
  value        = local.ha_cluster_password
  key_vault_id = azurerm_key_vault.sid_kv_user[0].id
}

// Store SPN of Azure Fence Agent for Hana Database in KV
resource "azurerm_key_vault_secret" "fence_agent_subscription_id" {
  count        = local.enable_fence_agent ? 1 : 0
  depends_on   = [azurerm_key_vault_access_policy.sid_kv_user_msi]
  name         = format("%s-sap-hana-fencing-agent-subscription-id", local.prefix)
  value        = local.fence_agent_subscription_id
  key_vault_id = azurerm_key_vault.sid_kv_user[0].id
}

resource "azurerm_key_vault_secret" "fence_agent_tenant_id" {
  count        = local.enable_fence_agent ? 1 : 0
  depends_on   = [azurerm_key_vault_access_policy.sid_kv_user_msi]
  name         = format("%s-sap-hana-fencing-agent-tenant-id", local.prefix)
  value        = local.fence_agent_tenant_id
  key_vault_id = azurerm_key_vault.sid_kv_user[0].id
}

resource "azurerm_key_vault_secret" "fence_agent_client_id" {
  count        = local.enable_fence_agent ? 1 : 0
  depends_on   = [azurerm_key_vault_access_policy.sid_kv_user_msi]
  name         = format("%s-sap-hana-fencing-agent-client-id", local.prefix)
  value        = local.fence_agent_client_id
  key_vault_id = azurerm_key_vault.sid_kv_user[0].id
}

resource "azurerm_key_vault_secret" "fence_agent_client_secret" {
  count        = local.enable_fence_agent ? 1 : 0
  depends_on   = [azurerm_key_vault_access_policy.sid_kv_user_msi]
  name         = format("%s-sap-hana-fencing-agent-client-secret", local.prefix)
  value        = local.fence_agent_client_secret
  key_vault_id = azurerm_key_vault.sid_kv_user[0].id
}
