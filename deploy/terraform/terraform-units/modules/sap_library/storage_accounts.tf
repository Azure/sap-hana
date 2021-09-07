/*
  Description:
  Set up storage accounts for sap library 
*/

// Imports existing storage account to use for tfstate
data "azurerm_storage_account" "storage_tfstate" {
  count               = local.sa_tfstate_exists ? 1 : 0
  name                = split("/", local.sa_tfstate_arm_id)[8]
  resource_group_name = split("/", local.sa_tfstate_arm_id)[4]
}

// Creates storage account for storing tfstate
resource "azurerm_storage_account" "storage_tfstate" {
  count                     = local.sa_tfstate_exists ? 0 : 1
  name                      = local.sa_tfstate_name
  resource_group_name       = local.rg_name
  location                  = local.rg_library_location
  account_replication_type  = local.sa_tfstate_account_replication_type
  account_tier              = local.sa_tfstate_account_tier
  account_kind              = local.sa_tfstate_account_kind
  enable_https_traffic_only = local.sa_tfstate_enable_secure_transfer
  allow_blob_public_access  = true
  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }
}

data "azurerm_storage_container" "storagecontainer_tfstate" {
  count                = local.sa_tfstate_container_exists ? 1 : 0
  name                 = local.sa_tfstate_container_name
  storage_account_name = local.sa_tfstate_exists ? data.azurerm_storage_account.storage_tfstate[0].name : azurerm_storage_account.storage_tfstate[0].name
}

// Creates the storage container inside the storage account for sapsystem
resource "azurerm_storage_container" "storagecontainer_tfstate" {
  count                 = local.sa_tfstate_container_exists ? 0 : 1
  name                  = local.sa_tfstate_container_name
  storage_account_name  = local.sa_tfstate_exists ? data.azurerm_storage_account.storage_tfstate[0].name : azurerm_storage_account.storage_tfstate[0].name
  container_access_type = local.sa_tfstate_container_access_type
}

//Ansible container

data "azurerm_storage_container" "storagecontainer_ansible" {
  count                = local.sa_ansible_container_exists ? 1 : 0
  name                 = local.sa_ansible_container_name
  storage_account_name = local.sa_tfstate_exists ? data.azurerm_storage_account.storage_tfstate[0].name : azurerm_storage_account.storage_tfstate[0].name
}

// Creates the storage container inside the storage account for sapsystem
resource "azurerm_storage_container" "storagecontainer_ansible" {
  count                 = local.sa_ansible_container_exists ? 0 : 1
  name                  = local.sa_ansible_container_name
  storage_account_name  = local.sa_tfstate_exists ? data.azurerm_storage_account.storage_tfstate[0].name : azurerm_storage_account.storage_tfstate[0].name
  container_access_type = local.sa_tfstate_container_access_type
}


// Imports existing storage account for storing SAP bits
data "azurerm_storage_account" "storage_sapbits" {
  count               = local.sa_sapbits_exists ? 1 : 0
  name                = split("/", local.sa_sapbits_arm_id)[8]
  resource_group_name = split("/", local.sa_sapbits_arm_id)[4]
}

// Creates storage account for storing SAP bits
resource "azurerm_storage_account" "storage_sapbits" {
  count                     = local.sa_sapbits_exists ? 0 : 1
  name                      = local.sa_sapbits_name
  resource_group_name       = local.rg_name
  location                  = local.rg_library_location
  account_replication_type  = local.sa_sapbits_account_replication_type
  account_tier              = local.sa_sapbits_account_tier
  account_kind              = local.sa_sapbits_account_kind
  enable_https_traffic_only = local.sa_sapbits_enable_secure_transfer
  // To support all access levels 'Blob' 'Private' and 'Container'
  allow_blob_public_access = true
  // TODO: soft delete for file share
}

// Imports existing storage blob container for SAP bits
data "azurerm_storage_container" "storagecontainer_sapbits" {
  count                = (local.sa_sapbits_blob_container_enable && local.sa_sapbits_blob_container_exists) ? 1 : 0
  name                 = local.sa_sapbits_blob_container_name
  storage_account_name = local.sa_sapbits_exists ? data.azurerm_storage_account.storage_sapbits[0].name : azurerm_storage_account.storage_sapbits[0].name
}

// Creates the storage container inside the storage account for SAP bits
resource "azurerm_storage_container" "storagecontainer_sapbits" {
  count                 = (local.sa_sapbits_blob_container_enable && !local.sa_sapbits_blob_container_exists) ? 1 : 0
  name                  = local.sa_sapbits_blob_container_name
  storage_account_name  = local.sa_sapbits_exists ? data.azurerm_storage_account.storage_sapbits[0].name : azurerm_storage_account.storage_sapbits[0].name
  container_access_type = local.sa_sapbits_container_access_type
}

// Creates file share inside the storage account for SAP bits
resource "azurerm_storage_share" "fileshare_sapbits" {
  count                = (local.sa_sapbits_file_share_enable && !local.sa_sapbits_file_share_exists) ? 1 : 0
  name                 = local.sa_sapbits_file_share_name
  storage_account_name = local.sa_sapbits_exists ? data.azurerm_storage_account.storage_sapbits[0].name : azurerm_storage_account.storage_sapbits[0].name
}

/* 
TBD: two options
1. deployer msi has contributor role(or less powerful role: Storage Account Contributor) to all the subscriptions it manages
2. when deploying storage accounts, deployer msi will be assgined a role as Storage Account Contributor, so it can move the terraform.tfstate from local to the storage account.
*/
// Assign contributor role to deployer's msi to access tfstate storage account
resource "azurerm_role_assignment" "deployer_msi_sa_tfstate" {
  count = local.deployer_defined && !local.sa_sapbits_exists ? (
    length(local.deployer_msi_principal_id) > 0 ? (
      1) : (
      0
    )) : (
    0
  )

  scope                = local.sa_tfstate_exists ? data.azurerm_storage_account.storage_tfstate[0].id : azurerm_storage_account.storage_tfstate[0].id
  role_definition_name = "Storage Account Contributor"
  principal_id         = local.deployer_msi_principal_id
}

# resource "azurerm_key_vault_secret" "saplibrary_access_key" {
#   count        = length(local.deployer_kv_user_arm_id)> 0 ? 1 : 0
#   name         = "sapbits-access-key"
#   value        = local.sa_sapbits_exists  ? data.azurerm_storage_account.storage_sapbits[0].primary_access_key : azurerm_storage_account.storage_sapbits[0].primary_access_key
#   key_vault_id = local.deployer_kv_user_arm_id
# }

