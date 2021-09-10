/*
  Description:
  Set up Key Vaults for sap landscape
*/

// Create private KV with access policy
resource "azurerm_key_vault" "kv_prvt" {
  provider                   = azurerm.main
  count                      = (local.enable_landscape_kv && !local.prvt_kv_exist) ? 1 : 0
  name                       = local.prvt_kv_name
  location                   = local.region
  resource_group_name        = local.rg_exists ? data.azurerm_resource_group.resource_group[0].name : azurerm_resource_group.resource_group[0].name
  tenant_id                  = local.service_principal.tenant_id
  soft_delete_retention_days = 7
  purge_protection_enabled   = var.enable_purge_control_for_keyvaults
  sku_name                   = "standard"

  access_policy {
    tenant_id = local.service_principal.tenant_id
    object_id = local.service_principal.object_id != "" ? local.service_principal.object_id : "00000000-0000-0000-0000-000000000000"

    secret_permissions = [
      "get",
    ]

  }

  lifecycle {
    ignore_changes = [
      soft_delete_enabled
    ]
  }

}

// Import an existing private Key Vault
data "azurerm_key_vault" "kv_prvt" {
  provider            = azurerm.main
  count               = (local.prvt_kv_exist) ? 1 : 0
  name                = local.prvt_kv_name
  resource_group_name = local.prvt_kv_rg_name
}


// Create user KV with access policy
resource "azurerm_key_vault" "kv_user" {
  provider                   = azurerm.main
  count                      = (local.enable_landscape_kv && !local.user_kv_exist) ? 1 : 0
  name                       = local.user_kv_name
  location                   = local.region
  resource_group_name        = local.rg_exists ? data.azurerm_resource_group.resource_group[0].name : azurerm_resource_group.resource_group[0].name
  tenant_id                  = local.service_principal.tenant_id
  soft_delete_retention_days = 7
  purge_protection_enabled   = var.enable_purge_control_for_keyvaults
  sku_name                   = "standard"

  access_policy {
    tenant_id = local.service_principal.tenant_id
    object_id = local.service_principal.object_id != "" ? local.service_principal.object_id : "00000000-0000-0000-0000-000000000000"

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Recover",
      "Restore",
      "Purge"
    ]

  }

  lifecycle {
    ignore_changes = [
      soft_delete_enabled,
      access_policy
    ]
  }
}

// Import an existing user Key Vault
data "azurerm_key_vault" "kv_user" {
  provider            = azurerm.main
  count               = (local.user_kv_exist) ? 1 : 0
  name                = local.user_kv_name
  resource_group_name = local.user_kv_rg_name
}

// Using TF tls to generate SSH key pair for iscsi devices and store in user KV
resource "tls_private_key" "iscsi" {
  count = (
    local.enable_landscape_kv
    && local.enable_iscsi_auth_key
    && !local.iscsi_key_exist
    && try(file(var.authentication.path_to_public_key), null) == null
  ) ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "azurerm_key_vault_secret" "iscsi_ppk" {
  provider     = azurerm.main
  count        = (local.enable_landscape_kv && local.enable_iscsi_auth_key && !local.iscsi_key_exist) ? 1 : 0
  content_type = ""
  name         = local.iscsi_ppk_name
  value        = local.iscsi_private_key
  key_vault_id = local.user_kv_exist ? local.user_key_vault_id : azurerm_key_vault.kv_user[0].id
}

resource "azurerm_key_vault_secret" "iscsi_pk" {
  provider     = azurerm.main
  count        = (local.enable_landscape_kv && local.enable_iscsi_auth_key && !local.iscsi_key_exist) ? 1 : 0
  content_type = ""
  name         = local.iscsi_pk_name
  value        = local.iscsi_public_key
  key_vault_id = local.user_kv_exist ? local.user_key_vault_id : azurerm_key_vault.kv_user[0].id
}

resource "azurerm_key_vault_secret" "iscsi_username" {
  provider     = azurerm.main
  count        = (local.enable_landscape_kv && local.enable_iscsi && !local.iscsi_username_exist) ? 1 : 0
  content_type = ""
  name         = local.iscsi_username_name
  value        = local.iscsi_auth_username
  key_vault_id = local.user_kv_exist ? local.user_key_vault_id : azurerm_key_vault.kv_user[0].id
}

resource "azurerm_key_vault_secret" "iscsi_password" {
  provider     = azurerm.main
  count        = (local.enable_landscape_kv && local.enable_iscsi_auth_password && !local.iscsi_pwd_exist) ? 1 : 0
  content_type = ""
  name         = local.iscsi_pwd_name
  value        = local.iscsi_auth_password
  key_vault_id = local.user_kv_exist ? local.user_key_vault_id : azurerm_key_vault.kv_user[0].id
}

// Generate random password if password is set as authentication type and user doesn't specify a password, and save in KV
resource "random_password" "iscsi_password" {
  count = (
    local.enable_landscape_kv
    && local.enable_iscsi_auth_password
    && !local.iscsi_pwd_exist
  && try(var.authentication.password, null) == null) ? 1 : 0

  length           = 32
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  special          = true
  override_special = "_%@"
}

// Import secrets about iSCSI
data "azurerm_key_vault_secret" "iscsi_pk" {
  provider     = azurerm.main
  count        = (local.enable_landscape_kv && local.enable_iscsi_auth_key && local.iscsi_key_exist) ? 1 : 0
  name         = local.iscsi_pk_name
  key_vault_id = local.user_key_vault_id
}

data "azurerm_key_vault_secret" "iscsi_ppk" {
  provider     = azurerm.main
  count        = (local.enable_landscape_kv && local.enable_iscsi_auth_key && local.iscsi_key_exist) ? 1 : 0
  name         = local.iscsi_ppk_name
  key_vault_id = local.user_key_vault_id
}

data "azurerm_key_vault_secret" "iscsi_password" {
  provider     = azurerm.main
  count        = (local.enable_landscape_kv && local.enable_iscsi_auth_password && local.iscsi_pwd_exist) ? 1 : 0
  name         = local.iscsi_pwd_name
  key_vault_id = local.user_key_vault_id
}

data "azurerm_key_vault_secret" "iscsi_username" {
  provider     = azurerm.main
  count        = (local.enable_landscape_kv && local.enable_iscsi && local.iscsi_username_exist) ? 1 : 0
  name         = local.iscsi_username_name
  key_vault_id = local.user_key_vault_id
}

// Using TF tls to generate SSH key pair for SID
resource "tls_private_key" "sid" {
  count     = (try(file(var.authentication.path_to_public_key), null) == null) ? 1 : 0
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
  provider     = azurerm.main
  count        = !local.sid_key_exist ? 1 : 0
  content_type = ""
  name         = local.sid_ppk_name
  value        = local.sid_private_key
  key_vault_id = local.user_kv_exist ? local.user_key_vault_id : azurerm_key_vault.kv_user[0].id
}

data "azurerm_key_vault_secret" "sid_ppk" {
  provider     = azurerm.main
  count        = (local.sid_key_exist) ? 1 : 0
  name         = local.sid_ppk_name
  key_vault_id = local.user_key_vault_id
}

resource "azurerm_key_vault_secret" "sid_pk" {
  provider     = azurerm.main
  count        = !local.sid_key_exist ? 1 : 0
  content_type = ""
  name         = local.sid_pk_name
  value        = local.sid_public_key
  key_vault_id = local.user_kv_exist ? local.user_key_vault_id : azurerm_key_vault.kv_user[0].id
}

data "azurerm_key_vault_secret" "sid_pk" {
  provider     = azurerm.main
  count        = (local.sid_key_exist) ? 1 : 0
  name         = local.sid_pk_name
  key_vault_id = local.user_key_vault_id
}


// Credentials will be stored in the existing KV if specified, otherwise will be stored in a newly provisioned KV 
resource "azurerm_key_vault_secret" "sid_username" {
  provider     = azurerm.main
  count        = (!local.sid_credentials_secret_exist) ? 1 : 0
  content_type = ""
  name         = local.sid_username_secret_name
  value        = local.input_sid_username
  key_vault_id = local.user_kv_exist ? local.user_key_vault_id : azurerm_key_vault.kv_user[0].id
}

data "azurerm_key_vault_secret" "sid_username" {
  provider     = azurerm.main
  count        = (local.sid_credentials_secret_exist) ? 1 : 0
  name         = local.sid_username_secret_name
  key_vault_id = local.user_key_vault_id
}

resource "azurerm_key_vault_secret" "sid_password" {
  provider     = azurerm.main
  count        = (!local.sid_credentials_secret_exist) ? 1 : 0
  name         = local.sid_password_secret_name
  content_type = ""
  value        = local.input_sid_password
  key_vault_id = local.user_kv_exist ? local.user_key_vault_id : azurerm_key_vault.kv_user[0].id
}

data "azurerm_key_vault_secret" "sid_password" {
  provider     = azurerm.main
  count        = (local.sid_credentials_secret_exist) ? 1 : 0
  name         = local.sid_password_secret_name
  key_vault_id = local.user_key_vault_id
}


//Witness access key
resource "azurerm_key_vault_secret" "witness_access_key" {
  provider     = azurerm.main
  count        = 1
  content_type = ""
  name         = replace(format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.witness_accesskey), "/[^A-Za-z0-9-]/", "")
  value        = length(var.witness_storage_account.arm_id) > 0 ? data.azurerm_storage_account.witness_storage[0].primary_access_key : azurerm_storage_account.witness_storage[0].primary_access_key
  key_vault_id = local.user_kv_exist ? local.user_key_vault_id : azurerm_key_vault.kv_user[0].id
}

//Witness access key
resource "azurerm_key_vault_secret" "witness_name" {
  provider     = azurerm.main
  count        = 1
  content_type = ""
  name         = replace(format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.witness_name), "/[^A-Za-z0-9-]/", "")
  value        = length(var.witness_storage_account.arm_id) > 0 ? data.azurerm_storage_account.witness_storage[0].name : azurerm_storage_account.witness_storage[0].name
  key_vault_id = local.user_kv_exist ? local.user_key_vault_id : azurerm_key_vault.kv_user[0].id
}

resource "azurerm_key_vault_access_policy" "kv_user_msi" {
  provider = azurerm.main
  count = local.user_kv_exist ? (
    0) : (
    length(var.deployer_tfstate) > 0 ? (
      length(var.deployer_tfstate.deployer_uai) == 2 ? (
        1) : (
        0
      )) : (
      0
    )
  )
  key_vault_id = local.user_kv_exist ? local.user_key_vault_id : azurerm_key_vault.kv_user[0].id

  tenant_id = var.deployer_tfstate.deployer_uai.tenant_id
  object_id = var.deployer_tfstate.deployer_uai.principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
}



//Witness access key
resource "azurerm_key_vault_secret" "deployer_kv_user_name" {
  provider     = azurerm.main
  count        = length(trimspace(local.deployer_kv_user_name)) > 0 ? 1 : 0
  content_type = ""
  name         = "deployer-kv-name"
  value        = local.deployer_kv_user_name
  key_vault_id = local.user_kv_exist ? local.user_key_vault_id : azurerm_key_vault.kv_user[0].id
}

