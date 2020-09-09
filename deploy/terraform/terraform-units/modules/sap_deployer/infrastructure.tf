/*
Description:

  Define infrastructure resources for deployer(s).
*/

// Random 8 char identifier for sap deployer resources
resource "random_id" "deployer" {
  byte_length = 4
}

// Create managed resource group for sap deployer with CanNotDelete lock
resource "azurerm_resource_group" "deployer" {
  count    = local.enable_deployers ? 1 : 0
  name     = local.rg_name
  location = local.region
}

// TODO: Add management lock when this issue is addressed https://github.com/terraform-providers/terraform-provider-azurerm/issues/5473

// Create/Import management vnet
resource "azurerm_virtual_network" "vnet_mgmt" {
  count               = (local.enable_deployers && ! local.vnet_mgmt_exists) ? 1 : 0
  name                = local.vnet_mgmt_name
  location            = azurerm_resource_group.deployer[0].location
  resource_group_name = azurerm_resource_group.deployer[0].name
  address_space       = [local.vnet_mgmt_addr]
}

data "azurerm_virtual_network" "vnet_mgmt" {
  count               = (local.enable_deployers && local.vnet_mgmt_exists) ? 1 : 0
  name                = split("/", local.vnet_mgmt_arm_id)[8]
  resource_group_name = split("/", local.vnet_mgmt_arm_id)[4]
}

// Create/Import management subnet
resource "azurerm_subnet" "subnet_mgmt" {
  count                = (local.enable_deployers && ! local.sub_mgmt_exists) ? 1 : 0
  name                 = local.sub_mgmt_name
  resource_group_name  = local.vnet_mgmt_exists ? data.azurerm_virtual_network.vnet_mgmt[0].resource_group_name : azurerm_virtual_network.vnet_mgmt[0].resource_group_name
  virtual_network_name = local.vnet_mgmt_exists ? data.azurerm_virtual_network.vnet_mgmt[0].name : azurerm_virtual_network.vnet_mgmt[0].name
  address_prefixes     = [local.sub_mgmt_prefix]
}

data "azurerm_subnet" "subnet_mgmt" {
  count                = (local.enable_deployers && local.sub_mgmt_exists) ? 1 : 0
  name                 = split("/", local.sub_mgmt_arm_id)[10]
  resource_group_name  = split("/", local.sub_mgmt_arm_id)[4]
  virtual_network_name = split("/", local.sub_mgmt_arm_id)[8]
}

// Creates boot diagnostics storage account for Deployer
resource "azurerm_storage_account" "deployer" {
  count                     = local.enable_deployers ? 1 : 0
  name                      = lower(format("%s%s", local.sa_prefix, substr(local.postfix, 0, 4)))
  resource_group_name       = azurerm_resource_group.deployer[0].name
  location                  = azurerm_resource_group.deployer[0].location
  account_replication_type  = "LRS"
  account_tier              = "Standard"
  enable_https_traffic_only = local.enable_secure_transfer
}

// Create private KV with access policy
data "azurerm_client_config" "deployer" {}

resource "azurerm_key_vault" "kv_prvt" {
  count                      = local.enable_deployers ? 1 : 0
  name                       = format("%sprvt%s", local.kv_prefix, upper(substr(local.postfix, 0, 3)))
  location                   = azurerm_resource_group.deployer[0].location
  resource_group_name        = azurerm_resource_group.deployer[0].name
  tenant_id                  = data.azurerm_client_config.deployer.tenant_id
  soft_delete_enabled        = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = true

  sku_name = "standard"
}

resource "azurerm_key_vault_access_policy" "kv_prvt_msi" {
  count        = local.enable_deployers ? 1 : 0
  key_vault_id = azurerm_key_vault.kv_prvt[0].id

  tenant_id = data.azurerm_client_config.deployer.tenant_id
  object_id = azurerm_user_assigned_identity.deployer.principal_id

  secret_permissions = [
    "get",
  ]
}

// Create user KV with access policy
resource "azurerm_key_vault" "kv_user" {
  count                      = local.enable_deployers ? 1 : 0
  name                       = format("%suser%s", local.kv_prefix, upper(substr(local.postfix, 0, 3)))
  location                   = azurerm_resource_group.deployer[0].location
  resource_group_name        = azurerm_resource_group.deployer[0].name
  tenant_id                  = data.azurerm_client_config.deployer.tenant_id
  soft_delete_enabled        = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = true

  sku_name = "standard"
}

resource "azurerm_key_vault_access_policy" "kv_user_msi" {
  count        = local.enable_deployers ? 1 : 0
  key_vault_id = azurerm_key_vault.kv_user[0].id

  tenant_id = data.azurerm_client_config.deployer.tenant_id
  object_id = azurerm_user_assigned_identity.deployer.principal_id

  secret_permissions = [
    "delete",
    "get",
    "list",
    "set",
  ]
}

resource "azurerm_key_vault_access_policy" "kv_user_portal" {
  count        = local.enable_deployers ? 1 : 0
  key_vault_id = azurerm_key_vault.kv_user[0].id

  tenant_id = data.azurerm_client_config.deployer.tenant_id
  object_id = data.azurerm_client_config.deployer.object_id

  secret_permissions = [
    "delete",
    "get",
    "list",
    "set",
  ]
}

// Using TF tls to generate SSH key pair and store in user KV
resource "tls_private_key" "deployer" {
  count = (
    local.enable_deployers
    && local.enable_key
    && (try(file(var.sshkey.path_to_public_key), "") == "" ? true : false)
  ) ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

/*
 To force dependency between kv access policy and secrets. Expected behavior:
 https://github.com/terraform-providers/terraform-provider-azurerm/issues/4971
*/

resource "azurerm_key_vault_secret" "ppk" {
  depends_on   = [azurerm_key_vault_access_policy.kv_user_portal[0]]
  count        = (local.enable_deployers && local.enable_key) ? 1 : 0
  name         = format("%s-sshkey", local.prefix)
  value        = local.private_key
  key_vault_id = azurerm_key_vault.kv_user[0].id
}

resource "azurerm_key_vault_secret" "pk" {
  depends_on   = [azurerm_key_vault_access_policy.kv_user_portal[0]]
  count        = (local.enable_deployers && local.enable_key) ? 1 : 0
  name         = format("%s-sshkey-pub", local.prefix)
  value        = local.public_key
  key_vault_id = azurerm_key_vault.kv_user[0].id
}

// Generate random password if password is set as authentication type, and save in KV
resource "random_password" "deployer" {
  count = (
    local.enable_deployers
    && local.enable_password
    && local.input_pwd == null ? true : false
  ) ? 1 : 0
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "azurerm_key_vault_secret" "pwd" {
  depends_on   = [azurerm_key_vault_access_policy.kv_user_portal[0]]
  count        = (local.enable_deployers && local.enable_password) ? 1 : 0
  name         = format("%s-password", local.prefix)
  value        = local.password
  key_vault_id = azurerm_key_vault.kv_user[0].id
}
