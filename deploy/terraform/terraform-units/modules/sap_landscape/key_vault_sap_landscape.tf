/*
  Description:
  Set up Key Vaults for sap landscape
*/

// Create private KV with access policy
resource "azurerm_key_vault" "kv_prvt" {
  count                      = (local.enable_landscape_kv && ! local.prvt_kv_exist) ? 1 : 0
  name                       = local.prvt_kv_name
  location                   = local.region
  resource_group_name        = local.rg_exists ? data.azurerm_resource_group.resource_group[0].name : azurerm_resource_group.resource_group[0].name
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

// Import an existing private Key Vault
data "azurerm_key_vault" "kv_prvt" {
  count               = (local.prvt_kv_exist) ? 1 : 0
  name                = local.prvt_kv_name
  resource_group_name = local.prvt_kv_rg_name
}


// Create user KV with access policy
resource "azurerm_key_vault" "kv_user" {
  count                      = (local.enable_landscape_kv && ! local.user_kv_exist) ? 1 : 0
  name                       = local.user_kv_name
  location                   = local.region
  resource_group_name        = local.rg_exists ? data.azurerm_resource_group.resource_group[0].name : azurerm_resource_group.resource_group[0].name
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

// Import an existing user Key Vault
data "azurerm_key_vault" "kv_user" {
  count               = (local.user_kv_exist) ? 1 : 0
  name                = local.user_kv_name
  resource_group_name = local.user_kv_rg_name
}

// Using TF tls to generate SSH key pair for iscsi devices and store in user KV
resource "tls_private_key" "iscsi" {
  count = (
    local.enable_landscape_kv
    && local.enable_iscsi_auth_key
    && ! local.iscsi_key_exist
    && try(file(var.authentication.path_to_public_key), null) == null
  ) ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "azurerm_key_vault_secret" "iscsi_ppk" {
  count        = (local.enable_landscape_kv && local.enable_iscsi_auth_key && ! local.iscsi_key_exist) ? 1 : 0
  name         = local.iscsi_ppk_name
  value        = local.iscsi_private_key
  key_vault_id = local.user_kv_exist ? local.user_key_vault_id : azurerm_key_vault.kv_user[0].id
}

resource "azurerm_key_vault_secret" "iscsi_pk" {
  count        = (local.enable_landscape_kv && local.enable_iscsi_auth_key && ! local.iscsi_key_exist) ? 1 : 0
  name         = local.iscsi_pk_name
  value        = local.iscsi_public_key
  key_vault_id = local.user_kv_exist ? local.user_key_vault_id : azurerm_key_vault.kv_user[0].id
}

resource "azurerm_key_vault_secret" "iscsi_username" {
  count        = (local.enable_landscape_kv && local.enable_iscsi && ! local.iscsi_username_exist) ? 1 : 0
  name         = local.iscsi_username_name
  value        = local.iscsi_auth_username
  key_vault_id = local.user_kv_exist ? local.user_key_vault_id : azurerm_key_vault.kv_user[0].id
}

resource "azurerm_key_vault_secret" "iscsi_password" {
  count        = (local.enable_landscape_kv && local.enable_iscsi_auth_password && ! local.iscsi_pwd_exist) ? 1 : 0
  name         = local.iscsi_pwd_name
  value        = local.iscsi_auth_password
  key_vault_id = local.user_kv_exist ? local.user_key_vault_id : azurerm_key_vault.kv_user[0].id
}

// Generate random password if password is set as authentication type and user doesn't specify a password, and save in KV
resource "random_password" "iscsi_password" {
  count = (
    local.enable_landscape_kv
    && local.enable_iscsi_auth_password
    && ! local.iscsi_pwd_exist
  && try(local.var_iscsi.authentication.password, null) == null) ? 1 : 0

  length           = 32
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  special          = true
  override_special = "_%@"
}

// Import secrets about iSCSI
data "azurerm_key_vault_secret" "iscsi_pk" {
  count        = (local.enable_landscape_kv && local.enable_iscsi_auth_key && local.iscsi_key_exist) ? 1 : 0
  name         = local.iscsi_pk_name
  key_vault_id = local.user_key_vault_id
}

data "azurerm_key_vault_secret" "iscsi_ppk" {
  count        = (local.enable_landscape_kv && local.enable_iscsi_auth_key && local.iscsi_key_exist) ? 1 : 0
  name         = local.iscsi_ppk_name
  key_vault_id = local.user_key_vault_id
}

data "azurerm_key_vault_secret" "iscsi_password" {
  count        = (local.enable_landscape_kv && local.enable_iscsi_auth_password && local.iscsi_pwd_exist) ? 1 : 0
  name         = local.iscsi_pwd_name
  key_vault_id = local.user_key_vault_id
}

data "azurerm_key_vault_secret" "iscsi_username" {
  count        = (local.enable_landscape_kv && local.enable_iscsi && local.iscsi_username_exist) ? 1 : 0
  name         = local.iscsi_username_name
  key_vault_id = local.user_key_vault_id
}

// Using TF tls to generate SSH key pair for SID
resource "tls_private_key" "sid" {
  count = (
    local.enable_landscape_kv
    && try(file(var.authentication.path_to_public_key), null) == null
    && ! local.sid_key_exist
  ) ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "random_password" "created_password" {

  length      = 32
  min_upper   = 2
  min_lower   = 2
  min_numeric = 2
}


// Key pair/password will be stored in the existing KV if specified, otherwise will be stored in a newly provisioned KV 
resource "azurerm_key_vault_secret" "sid_ppk" {
  count        = !local.sid_key_exist ? 1 : 0
  name         = local.sid_ppk_name
  value        = local.sid_private_key
  key_vault_id = local.user_kv_exist ? local.user_key_vault_id : azurerm_key_vault.kv_user[0].id
}

data "azurerm_key_vault_secret" "sid_ppk" {
  count        = (local.sid_key_exist) ? 1 : 0
  name         = local.sid_ppk_name
  key_vault_id = local.user_key_vault_id
}

resource "azurerm_key_vault_secret" "sid_pk" {
  count        = !local.sid_key_exist ? 1 : 0
  name         = local.sid_pk_name
  value        = local.sid_public_key
  key_vault_id = local.user_kv_exist ? local.user_key_vault_id : azurerm_key_vault.kv_user[0].id
}

data "azurerm_key_vault_secret" "sid_pk" {
  count        = (local.sid_key_exist) ? 1 : 0
  name         = local.sid_pk_name
  key_vault_id = local.user_key_vault_id
}


// Credentials will be stored in the existing KV if specified, otherwise will be stored in a newly provisioned KV 
resource "azurerm_key_vault_secret" "sid_username" {
  count        = (!local.sid_credentials_secret_exist) ? 1 : 0
  name         = local.sid_username_secret_name
  value        = local.input_sid_username
  key_vault_id = local.user_kv_exist ? local.user_key_vault_id : azurerm_key_vault.kv_user[0].id
}

data "azurerm_key_vault_secret" "sid_username" {
  count        = (local.sid_credentials_secret_exist) ? 1 : 0
  name         = local.sid_username_secret_name
  key_vault_id = local.user_key_vault_id
}

resource "azurerm_key_vault_secret" "sid_password" {
  count        = (!local.sid_credentials_secret_exist) ? 1 : 0
  name         = local.sid_password_secret_name
  value        = local.input_sid_password
  key_vault_id = local.user_kv_exist ? local.user_key_vault_id : azurerm_key_vault.kv_user[0].id
}

data "azurerm_key_vault_secret" "sid_password" {
  count        = (local.sid_credentials_secret_exist) ? 1 : 0
  name         = local.sid_password_secret_name
  key_vault_id = local.user_key_vault_id
}
