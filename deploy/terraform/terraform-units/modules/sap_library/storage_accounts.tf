/*
  Description:
  Set up storage accounts for sap library 
*/

// Imports existing storage account to use for tfstate
data "azurerm_storage_account" "storage_tfstate" {
  count               = local.sa_tfstate_exists ? 1 : 0
  name                = split("/", local.sa_tfstate_arm_id.arm_id)[8]
  resource_group_name = split("/", local.sa_tfstate_arm_id.arm_id)[4]
}

// Creates storage account for storing tfstate
resource "azurerm_storage_account" "storage_tfstate" {
  count                     = local.sa_tfstate_exists ? 0 : 1
  name                      = local.sa_tfstate_name
  resource_group_name       = local.rg_library.name
  location                  = local.rg_library.location
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
  storage_account_name = local.sa_tfstate.name
}

// Creates the storage container inside the storage account for tfstate
resource "azurerm_storage_container" "storagecontainer_tfstate" {
  count                 = local.sa_tfstate_container_exists ? 0 : 1
  name                  = local.sa_tfstate_container_name
  storage_account_name  = local.sa_tfstate.name
  container_access_type = local.sa_tfstate_container_access_type
}

data "azurerm_storage_container" "storagecontainer_json" {
  count                = local.sa_json_container_exists ? 1 : 0
  name                 = local.sa_json_container_name
  storage_account_name = local.sa_tfstate.name
}

// Creates the storage container inside the storage account for json
resource "azurerm_storage_container" "storagecontainer_json" {
  count                 = local.sa_json_container_exists ? 0 : 1
  name                  = local.sa_json_container_name
  storage_account_name  = local.sa_tfstate.name
  container_access_type = local.sa_tfstate_container_access_type
}

data "azurerm_storage_container" "storagecontainer_deployer" {
  count                = local.sa_deployer_container_exists ? 1 : 0
  name                 = local.sa_deployer_container_name
  storage_account_name = local.sa_tfstate.name
}

// Creates the storage container inside the storage account for deployer
resource "azurerm_storage_container" "storagecontainer_deployer" {
  count                 = local.sa_deployer_container_exists ? 0 : 1
  name                  = local.sa_deployer_container_name
  storage_account_name  = local.sa_tfstate.name
  container_access_type = local.sa_tfstate_container_access_type
}

data "azurerm_storage_container" "storagecontainer_saplibrary" {
  count                = local.sa_saplibrary_container_exists ? 1 : 0
  name                 = local.sa_saplibrary_container_name
  storage_account_name = local.sa_tfstate.name
}

// Creates the storage container inside the storage account for saplibrary
resource "azurerm_storage_container" "storagecontainer_saplibrary" {
  count                 = local.sa_saplibrary_container_exists ? 0 : 1
  name                  = local.sa_saplibrary_container_name
  storage_account_name  = local.sa_tfstate.name
  container_access_type = local.sa_tfstate_container_access_type
}

// Imports existing storage account for storing SAP bits
data "azurerm_storage_account" "storage_sapbits" {
  count               = local.sa_sapbits_exists ? 1 : 0
  name                = split("/", local.sa_sapbits_arm_id.arm_id)[8]
  resource_group_name = split("/", local.sa_sapbits_arm_id.arm_id)[4]
}

// Creates storage account for storing SAP bits
resource "azurerm_storage_account" "storage_sapbits" {
  count                     = local.sa_sapbits_exists ? 0 : 1
  name                      = local.sa_sapbits_name
  resource_group_name       = local.rg_library.name
  location                  = local.rg_library.location
  account_replication_type  = local.sa_sapbits_account_replication_type
  account_tier              = local.sa_sapbits_account_tier
  account_kind              = local.sa_sapbits_account_kind
  enable_https_traffic_only = local.sa_sapbits_enable_secure_transfer
  // To support all access levels 'Blob' 'Private' and 'Container'
  allow_blob_public_access  = true
  // TODO: soft delete for file share
}

// Imports existing storage blob container for SAP bits
data "azurerm_storage_container" "storagecontainer_sapbits" {
  count                = (local.sa_sapbits_blob_container_enable && local.sa_sapbits_blob_container_exists) ? 1 : 0
  name                 = local.sa_sapbits_blob_container_name
  storage_account_name = local.sa_sapbits.name
}

// Creates the storage container inside the storage account for SAP bits
resource "azurerm_storage_container" "storagecontainer_sapbits" {
  count                 = (local.sa_sapbits_blob_container_enable && !local.sa_sapbits_blob_container_exists) ? 1 : 0
  name                  = local.sa_sapbits_blob_container_name
  storage_account_name  = local.sa_sapbits.name
  container_access_type = local.sa_sapbits_container_access_type
}

// Creates file share inside the storage account for SAP bits
resource "azurerm_storage_share" "fileshare_sapbits" {
  count                = (local.sa_sapbits_file_share_enable && !local.sa_sapbits_file_share_exists) ? 1 : 0
  name                 = local.sa_sapbits_file_share_name
  storage_account_name = local.sa_sapbits.name
}

// Generates random text for storage account name
resource "random_id" "post_fix" {
  keepers = {
    // Generate a new id only when a new resource group is defined
    resource_group = local.rg_exists ? data.azurerm_resource_group.library[0].name : azurerm_resource_group.library[0].name
  }
  byte_length = 4
}
