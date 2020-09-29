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
  && try(local.hdb.authentication.password, null) == null) ? 1 : 0
  length           = 16
  special          = true
  override_special = "_%@"
}

/*
 To force dependency between kv access policy and secrets. Expected behavior:
 https://github.com/terraform-providers/terraform-provider-azurerm/issues/4971
*/
// store the hdb logon username in KV
resource "azurerm_key_vault_secret" "auth_username" {
  depends_on   = [var.sid_kv_user_msi]
  count        = local.enable_auth_password ? 1 : 0
  name         = format("%s-%s-hdb-auth-username", local.prefix, local.sid)
  value        = local.sid_auth_username
  key_vault_id = local.sid_kv_user.id
}

// store the hdb logon password in KV
resource "azurerm_key_vault_secret" "auth_password" {
  depends_on   = [var.sid_kv_user_msi]
  count        = local.enable_auth_password ? 1 : 0
  name         = format("%s-%s-hdb-auth-password", local.prefix, local.sid)
  value        = local.sid_auth_password
  key_vault_id = local.sid_kv_user.id
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
  depends_on   = [var.sid_kv_user_msi]
  name         = format("%s-db-systemdb-password", local.prefix)
  value        = local.db_systemdb_password
  key_vault_id = local.sid_kv_user.id
}

resource "azurerm_key_vault_secret" "os_sidadm" {
  count        = local.enable_deployment ? 1 : 0
  depends_on   = [var.sid_kv_user_msi]
  name         = format("%s-os-sidadm-password", local.prefix)
  value        = local.os_sidadm_password
  key_vault_id = local.sid_kv_user.id
}

resource "azurerm_key_vault_secret" "os_sapadm" {
  count        = local.enable_deployment ? 1 : 0
  depends_on   = [var.sid_kv_user_msi]
  name         = format("%s-os-sapadm-password", local.prefix)
  value        = local.os_sapadm_password
  key_vault_id = local.sid_kv_user.id
}

resource "azurerm_key_vault_secret" "xsa_admin" {
  count        = local.enable_deployment ? 1 : 0
  depends_on   = [var.sid_kv_user_msi]
  name         = format("%s-xsa-admin-password", local.prefix)
  value        = local.xsa_admin_password
  key_vault_id = local.sid_kv_user.id
}

resource "azurerm_key_vault_secret" "cockpit_admin" {
  count        = local.enable_deployment ? 1 : 0
  depends_on   = [var.sid_kv_user_msi]
  name         = format("%s-cockpit-admin-password", local.prefix)
  value        = local.cockpit_admin_password
  key_vault_id = local.sid_kv_user.id
}

resource "azurerm_key_vault_secret" "ha_cluster" {
  count        = local.enable_deployment && local.hdb_ha ? 1 : 0
  depends_on   = [var.sid_kv_user_msi]
  name         = format("%s-ha-cluster-password", local.prefix)
  value        = local.ha_cluster_password
  key_vault_id = local.sid_kv_user.id
}

// Store SPN of Azure Fence Agent for Hana Database in KV
resource "azurerm_key_vault_secret" "fence_agent_subscription_id" {
  count        = local.enable_fence_agent ? 1 : 0
  depends_on   = [var.sid_kv_user_msi]
  name         = format("%s-sap-hana-fencing-agent-subscription-id", local.prefix)
  value        = local.fence_agent_subscription_id
  key_vault_id = local.sid_kv_user.id
}

resource "azurerm_key_vault_secret" "fence_agent_tenant_id" {
  count        = local.enable_fence_agent ? 1 : 0
  depends_on   = [var.sid_kv_user_msi]
  name         = format("%s-sap-hana-fencing-agent-tenant-id", local.prefix)
  value        = local.fence_agent_tenant_id
  key_vault_id = local.sid_kv_user.id
}

resource "azurerm_key_vault_secret" "fence_agent_client_id" {
  count        = local.enable_fence_agent ? 1 : 0
  depends_on   = [var.sid_kv_user_msi]
  name         = format("%s-sap-hana-fencing-agent-client-id", local.prefix)
  value        = local.fence_agent_client_id
  key_vault_id = local.sid_kv_user.id
}

resource "azurerm_key_vault_secret" "fence_agent_client_secret" {
  count        = local.enable_fence_agent ? 1 : 0
  depends_on   = [var.sid_kv_user_msi]
  name         = format("%s-sap-hana-fencing-agent-client-secret", local.prefix)
  value        = local.fence_agent_client_secret
  key_vault_id = local.sid_kv_user.id
}
