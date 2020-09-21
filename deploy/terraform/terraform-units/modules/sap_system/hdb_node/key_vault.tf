/*
  Description:
  Set up key vault for sap system
*/

data "azurerm_client_config" "deployer" {}

// Create private KV with access policy
resource "azurerm_key_vault" "kv_prvt" {
  count                      = local.enable_deployment ? 1 : 0
  name                       = local.kv_private_name
  location                   = local.region
  resource_group_name        = var.resource-group[0].name
  tenant_id                  = data.azurerm_client_config.deployer.tenant_id
  soft_delete_enabled        = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = true
  sku_name                   = "standard"
}

resource "azurerm_key_vault_access_policy" "kv_prvt_msi" {
  count        = local.enable_deployment ? 1 : 0
  key_vault_id = azurerm_key_vault.kv_prvt[0].id

  tenant_id = data.azurerm_client_config.deployer.tenant_id
  object_id = var.deployer-uai.principal_id

  secret_permissions = [
    "get",
  ]
}

// Create user KV with access policy
resource "azurerm_key_vault" "kv_user" {
  count                      = local.enable_deployment ? 1 : 0
  name                       = local.kv_user_name
  location                   = local.region
  resource_group_name        = var.resource-group[0].name
  tenant_id                  = data.azurerm_client_config.deployer.tenant_id
  soft_delete_enabled        = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = true

  sku_name = "standard"
}

resource "azurerm_key_vault_access_policy" "kv_user_msi" {
  count        = local.enable_deployment ? 1 : 0
  key_vault_id = azurerm_key_vault.kv_user[0].id
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
  count        = local.enable_deployment ? length(local.kv_users) : 0
  key_vault_id = azurerm_key_vault.kv_user[0].id
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
resource "random_password" "password" {
  count = (
    local.enable_auth_password
  && try(local.hdb.authentication.password, null) == null) ? 1 : 0
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
// store the logon username in KV
resource "azurerm_key_vault_secret" "auth_username" {
  depends_on   = [azurerm_key_vault_access_policy.kv_user_msi]
  count        = local.enable_auth_password ? 1 : 0
  name         = format("%s-sid-auth-username", local.prefix)
  value        = local.sid_auth_username
  key_vault_id = azurerm_key_vault.kv_user[0].id
}

// store the logon password in KV
resource "azurerm_key_vault_secret" "auth_password" {
  depends_on   = [azurerm_key_vault_access_policy.kv_user_msi]
  count        = local.enable_auth_password ? 1 : 0
  name         = format("%s-sid-auth-password", local.prefix)
  value        = local.sid_auth_password
  key_vault_id = azurerm_key_vault.kv_user[0].id
}


// Generate random passwords as hana database credentials
/* TODO: passwords generating enhancement. 
   Currently, six passwords for hana database credentials are generated regardless of how many passwords populated in credentials block. 
   If some of them is empty, one of these pre-generated passwords with a fixed index will be used.
*/
resource "random_password" "credentials" {
  count            = local.enable_deployment ? 6 : 0
  length           = 16
  special          = true
  override_special = "_%@"
}

// Store Hana database credentials as secrets in KV
resource "azurerm_key_vault_secret" "db_systemdb" {
  count        = local.enable_deployment ? 1 : 0
  depends_on   = [azurerm_key_vault_access_policy.kv_user_msi]
  name         = format("%s-db-systemdb-password", local.prefix)
  value        = local.db_systemdb_password
  key_vault_id = azurerm_key_vault.kv_user[0].id
}

resource "azurerm_key_vault_secret" "os_sidadm" {
  count        = local.enable_deployment ? 1 : 0
  depends_on   = [azurerm_key_vault_access_policy.kv_user_msi]
  name         = format("%s-os-sidadm-password", local.prefix)
  value        = local.os_sidadm_password
  key_vault_id = azurerm_key_vault.kv_user[0].id
}

resource "azurerm_key_vault_secret" "os_sapadm" {
  count        = local.enable_deployment ? 1 : 0
  depends_on   = [azurerm_key_vault_access_policy.kv_user_msi]
  name         = format("%s-os-sapadm-password", local.prefix)
  value        = local.os_sapadm_password
  key_vault_id = azurerm_key_vault.kv_user[0].id
}

resource "azurerm_key_vault_secret" "xsa_admin" {
  count        = local.enable_deployment ? 1 : 0
  depends_on   = [azurerm_key_vault_access_policy.kv_user_msi]
  name         = format("%s-xsa-admin-password", local.prefix)
  value        = local.xsa_admin_password
  key_vault_id = azurerm_key_vault.kv_user[0].id
}

resource "azurerm_key_vault_secret" "cockpit_admin" {
  count        = local.enable_deployment ? 1 : 0
  depends_on   = [azurerm_key_vault_access_policy.kv_user_msi]
  name         = format("%s-cockpit-admin-password", local.prefix)
  value        = local.cockpit_admin_password
  key_vault_id = azurerm_key_vault.kv_user[0].id
}

resource "azurerm_key_vault_secret" "ha_cluster" {
  count        = local.enable_deployment && local.hdb_ha ? 1 : 0
  depends_on   = [azurerm_key_vault_access_policy.kv_user_msi]
  name         = format("%s-ha-cluster-password", local.prefix)
  value        = local.ha_cluster_password
  key_vault_id = azurerm_key_vault.kv_user[0].id
}

// retrieve public key from sap landscape's Key vault
data "azurerm_key_vault_secret" "sid_pk" {
  count        = local.enable_auth_key ? 1 : 0
  name         = local.secret_sid_pk_name
  key_vault_id = local.kv_landscape_id
}
