/*
  Description:
  Set up key vault for sap system
*/

// retrieve public key from sap landscape's Key vault
data "azurerm_key_vault_secret" "sid_pk" {
  provider     = azurerm.main
  count        = local.use_local_credentials ? 0 : 1
  name         = var.landscape_tfstate.sid_public_key_secret_name
  key_vault_id = local.user_key_vault_id
}

data "azurerm_key_vault_secret" "sid_username" {
  provider     = azurerm.main
  count        = local.use_local_credentials ? 0 : 1
  name         = try(var.landscape_tfstate.sid_username_secret_name, trimprefix(format("%s-sid-username", var.naming.prefix.VNET), "-"))
  key_vault_id = local.user_key_vault_id
}

data "azurerm_key_vault_secret" "sid_password" {
  provider     = azurerm.main
  count        = local.use_local_credentials ? 0 : 1
  name         = try(var.landscape_tfstate.sid_password_secret_name, trimprefix(format("%s-sid-password", var.naming.prefix.VNET), "-"))
  key_vault_id = local.user_key_vault_id
}


// Create private KV with access policy
resource "azurerm_key_vault" "sid_kv_prvt" {
  provider                   = azurerm.main
  count                      = local.enable_sid_deployment && !local.prvt_kv_override ? 1 : 0
  name                       = local.prvt_kv_name
  location                   = local.region
  resource_group_name        = local.rg_exists ? data.azurerm_resource_group.resource_group[0].name : azurerm_resource_group.resource_group[0].name
  tenant_id                  = local.service_principal.tenant_id
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

  lifecycle {
    ignore_changes = [
      soft_delete_enabled
    ]
  }

}

// Import an existing private Key Vault
data "azurerm_key_vault" "sid_kv_prvt" {
  provider            = azurerm.main
  count               = (local.enable_sid_deployment && local.prvt_kv_override) ? 1 : 0
  name                = local.prvt_kv_name
  resource_group_name = local.prvt_kv_rg_name
}

// Create user KV with access policy
resource "azurerm_key_vault" "sid_kv_user" {
  provider                   = azurerm.main
  count                      = local.enable_sid_deployment && !local.user_kv_override ? 1 : 0
  name                       = local.user_kv_name
  location                   = local.region
  resource_group_name        = local.rg_exists ? data.azurerm_resource_group.resource_group[0].name : azurerm_resource_group.resource_group[0].name
  tenant_id                  = local.service_principal.tenant_id
  soft_delete_retention_days = 7
  purge_protection_enabled   = true
  sku_name                   = "standard"

  access_policy {
    tenant_id = local.service_principal.tenant_id
    object_id = local.service_principal.object_id

    secret_permissions = [
      "Delete",
      "Get",
      "List",
      "Set",
      "Restore",
      "Recover",
      "Purge"
    ]

  }

  lifecycle {
    ignore_changes = [
      soft_delete_enabled
    ]
  }

}

// Import an existing user Key Vault
data "azurerm_key_vault" "sid_kv_user" {
  provider            = azurerm.main
  count               = (local.enable_sid_deployment && local.user_kv_override) ? 1 : 0
  name                = local.user_kv_name
  resource_group_name = local.user_kv_rg_name
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

// Generate random password if password is set as authentication type and user doesn't specify a password, and save in KV
resource "random_password" "password" {
  count            = !local.use_local_credentials ? 0 : length(trimspace(try(var.authentication.password, ""))) > 0 ? 0 : 1
  length           = 32
  special          = true
  override_special = "_%@"
}

// Store the logon username in KV when authentication type is password
resource "azurerm_key_vault_secret" "auth_username" {
  provider     = azurerm.main
  count        = local.enable_sid_deployment && local.use_local_credentials ? 1 : 0
  name         = format("%s-username", local.prefix)
  value        = local.sid_auth_username
  key_vault_id = azurerm_key_vault.sid_kv_user[0].id
}

// Store the password in KV when authentication type is password
resource "azurerm_key_vault_secret" "auth_password" {
  provider     = azurerm.main
  count        = local.enable_sid_deployment && local.use_local_credentials ? 1 : 0
  name         = format("%s-password", local.prefix)
  value        = var.authentication.password
  key_vault_id = azurerm_key_vault.sid_kv_user[0].id
}

// Using TF tls to generate SSH key pair and store in user KV
resource "tls_private_key" "sdu" {
  count = (
    local.use_local_credentials
    && (try(file(var.authentication.path_to_public_key), "") == "")
  ) ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}


// By default the SSH keys are stored in landscape key vault. By defining the authenticationb block the SDU keyvault
resource "azurerm_key_vault_secret" "sdu_private_key" {
  provider     = azurerm.main
  count        = local.enable_sid_deployment && local.use_local_credentials ? 1 : 0
  name         = format("%s-sshkey", local.prefix)
  value        = local.sid_private_key
  key_vault_id = azurerm_key_vault.sid_kv_user[0].id
}

resource "azurerm_key_vault_secret" "sdu_public_key" {
  provider     = azurerm.main
  count        = local.enable_sid_deployment && local.use_local_credentials ? 1 : 0
  name         = format("%s-sshkey-pub", local.prefix)
  value        = local.sid_public_key
  key_vault_id = azurerm_key_vault.sid_kv_user[0].id
}
