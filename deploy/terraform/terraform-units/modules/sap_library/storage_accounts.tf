/*
  Description:
  Set up storage accounts for sap library 
*/

// Imports existing storage account to use for tfstate
data "azurerm_storage_account" "storage-tfstate" {
  count               = local.sa_tfstate_exists ? 1 : 0
  name                = split("/", local.sa_tfstate_arm_id.arm_id)[8]
  resource_group_name = split("/", local.sa_tfstate_arm_id.arm_id)[4]
}

// Creates storage account for storing tfstate
resource "azurerm_storage_account" "storage-tfstate" {
  count                     = local.sa_tfstate_exists ? 0 : 1
  name                      = local.sa_tfstate_name
  resource_group_name       = local.rg_exists ? data.azurerm_resource_group.library[0].name : azurerm_resource_group.library[0].name
  location                  = local.rg_exists ? data.azurerm_resource_group.library[0].location : azurerm_resource_group.library[0].location
  account_replication_type  = "LRS"
  account_tier              = local.sa_tfstate_account_tier
  account_kind              = local.sa_tfstate_account_kind
  enable_https_traffic_only = local.sa_tfstate_enable_secure_transfer
  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }
}

// Creates the storage container inside the storage account for tfstate
resource "azurerm_storage_container" "storagecontainer-tfstate" {
  count                 = local.sa_tfstate_exists ? 0 : 1
  name                  = local.sa_tfstate_container_name
  storage_account_name  = local.sa_tfstate_exists ? data.azurerm_storage_account.storage-tfstate[0].name : azurerm_storage_account.storage-tfstate[0].name
  container_access_type = local.sa_tfstate_container_access_type
}

// Creates the storage container inside the storage account for json
resource "azurerm_storage_container" "storagecontainer-json" {
  count                 = local.sa_tfstate_exists ? 0 : 1
  name                  = local.sa_json_container_name
  storage_account_name  = local.sa_tfstate_exists ? data.azurerm_storage_account.storage-tfstate[0].name : azurerm_storage_account.storage-tfstate[0].name
  container_access_type = local.sa_tfstate_container_access_type
}

// Creates the storage container inside the storage account for deployer
resource "azurerm_storage_container" "storagecontainer-deployer" {
  count                 = local.sa_tfstate_exists ? 0 : 1
  name                  = local.sa_deployer_container_name
  storage_account_name  = local.sa_tfstate_exists ? data.azurerm_storage_account.storage-tfstate[0].name : azurerm_storage_account.storage-tfstate[0].name
  container_access_type = local.sa_tfstate_container_access_type
}

// Creates the storage container inside the storage account for saplibrary
resource "azurerm_storage_container" "storagecontainer-saplibrary" {
  count                 = local.sa_tfstate_exists ? 0 : 1
  name                  = local.sa_saplibrary_container_name
  storage_account_name  = local.sa_tfstate_exists ? data.azurerm_storage_account.storage-tfstate[0].name : azurerm_storage_account.storage-tfstate[0].name
  container_access_type = local.sa_tfstate_container_access_type
}

// Imports existing storage account to use for SAP bits
data "azurerm_storage_account" "storage-sapbits" {
  count               = local.sa_sapbits_exists ? 1 : 0
  name                = split("/", local.sa_sapbits_arm_id.arm_id)[8]
  resource_group_name = split("/", local.sa_sapbits_arm_id.arm_id)[4]
}

// Creates storage account for storing SAP Bits
resource "azurerm_storage_account" "storage-sapbits" {
  count                     = local.sa_sapbits_exists ? 0 : 1
  name                      = local.sa_sapbits_name
  resource_group_name       = local.rg_exists ? data.azurerm_resource_group.library[0].name : azurerm_resource_group.library[0].name
  location                  = local.rg_exists ? data.azurerm_resource_group.library[0].location : azurerm_resource_group.library[0].location
  account_replication_type  = "LRS"
  account_tier              = local.sa_sapbits_account_tier
  account_kind              = local.sa_sapbits_account_kind
  enable_https_traffic_only = local.sa_sapbits_enable_secure_transfer
  // TODO: soft delete for file share
}

// Creates the storage container inside the storage account for SAP bits
resource "azurerm_storage_container" "storagecontainer-sapbits" {
  count                 = local.sa_sapbits_exists ? 0 : (local.sa_sapbits_blob_container_name == "null" ? 0 : 1)
  name                  = local.sa_sapbits_blob_container_name
  storage_account_name  = azurerm_storage_account.storage-sapbits[0].name
  container_access_type = local.sa_sapbits_container_access_type
}

// Creates file share inside the storage account for SAP bits
resource "azurerm_storage_share" "fileshare-sapbits" {
  count                = local.sa_sapbits_exists ? 0 : (local.sa_sapbits_file_share_name == "" ? 0 : 1)
  name                 = local.sa_sapbits_file_share_name
  storage_account_name = azurerm_storage_account.storage-sapbits[0].name
}

// Generates random text for storage account name
resource "random_id" "post-fix" {
  keepers = {
    // Generate a new id only when a new resource group is defined
    resource_group = local.rg_exists ? data.azurerm_resource_group.library[0].name : azurerm_resource_group.library[0].name
  }
  byte_length = 4
}
