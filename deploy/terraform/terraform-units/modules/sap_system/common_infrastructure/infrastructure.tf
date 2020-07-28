##################################################################################################################
# RESOURCES
##################################################################################################################

# RESOURCE GROUP =================================================================================================

# Creates the resource group
resource "azurerm_resource_group" "resource-group" {
  count    = local.rg_exists ? 0 : 1
  name     = local.rg_name
  location = local.region
}

# Imports data of existing resource group
data "azurerm_resource_group" "resource-group" {
  count = local.rg_exists ? 1 : 0
  name  = split("/", local.rg_arm_id)[4]
}

# VNETs ==========================================================================================================

# Creates the SAP VNET
resource "azurerm_virtual_network" "vnet-sap" {
  count               = local.vnet_sap_exists ? 0 : 1
  name                = local.vnet_sap_name
  location            = local.rg_exists ? data.azurerm_resource_group.resource-group[0].location : azurerm_resource_group.resource-group[0].location
  resource_group_name = local.rg_exists ? data.azurerm_resource_group.resource-group[0].name : azurerm_resource_group.resource-group[0].name
  address_space       = [local.vnet_sap_addr]
}

# Imports data of existing SAP VNET
data "azurerm_virtual_network" "vnet-sap" {
  count               = local.vnet_sap_exists ? 1 : 0
  name                = split("/", local.vnet_sap_arm_id)[8]
  resource_group_name = split("/", local.vnet_sap_arm_id)[4]
}

# VNET PEERINGs ==================================================================================================

# Peers management VNET to SAP VNET
resource "azurerm_virtual_network_peering" "peering-management-sap" {
  name                         = substr("${var.vnet-mgmt.resource_group_name}_${var.vnet-mgmt.name}-${local.vnet_sap_exists ? data.azurerm_virtual_network.vnet-sap[0].resource_group_name : azurerm_virtual_network.vnet-sap[0].resource_group_name}_${local.vnet_sap_exists ? data.azurerm_virtual_network.vnet-sap[0].name : azurerm_virtual_network.vnet-sap[0].name}", 0, 80)
  resource_group_name          = var.vnet-mgmt.resource_group_name
  virtual_network_name         = var.vnet-mgmt.name
  remote_virtual_network_id    = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet-sap[0].id : azurerm_virtual_network.vnet-sap[0].id
  allow_virtual_network_access = true
}

# Peers SAP VNET to management VNET
resource "azurerm_virtual_network_peering" "peering-sap-management" {
  name                         = substr("${local.vnet_sap_exists ? data.azurerm_virtual_network.vnet-sap[0].resource_group_name : azurerm_virtual_network.vnet-sap[0].resource_group_name}_${local.vnet_sap_exists ? data.azurerm_virtual_network.vnet-sap[0].name : azurerm_virtual_network.vnet-sap[0].name}-${var.vnet-mgmt.resource_group_name}_${var.vnet-mgmt.name}", 0, 80)
  resource_group_name          = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet-sap[0].resource_group_name : azurerm_virtual_network.vnet-sap[0].resource_group_name
  virtual_network_name         = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet-sap[0].name : azurerm_virtual_network.vnet-sap[0].name
  remote_virtual_network_id    = var.vnet-mgmt.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# STORAGE ACCOUNTS ===============================================================================================

# Generates random text for boot diagnostics storage account name
resource "random_id" "random-id" {
  keepers = {
    # Generate a new id only when a new resource group is defined
    resource_group = local.rg_exists ? data.azurerm_resource_group.resource-group[0].name : azurerm_resource_group.resource-group[0].name
  }
  byte_length = 4
}

# Creates storage account for storing SAP Bits
resource "azurerm_storage_account" "storage-sapbits" {
  count                     = local.sa_sapbits_exists ? 0 : 1
  name                      = local.sa_name
  resource_group_name       = local.rg_exists ? data.azurerm_resource_group.resource-group[0].name : azurerm_resource_group.resource-group[0].name
  location                  = local.rg_exists ? data.azurerm_resource_group.resource-group[0].location : azurerm_resource_group.resource-group[0].location
  account_replication_type  = "LRS"
  account_tier              = local.sa_account_tier
  account_kind              = local.sa_account_kind
  enable_https_traffic_only = var.options.enable_secure_transfer == "" ? true : var.options.enable_secure_transfer
}

# Creates the storage container inside the storage account for SAP bits
resource "azurerm_storage_container" "storagecontainer-sapbits" {
  count                 = local.sa_sapbits_exists ? 0 : (local.sa_blob_container_name == "null" ? 0 : 1)
  name                  = local.sa_blob_container_name
  storage_account_name  = azurerm_storage_account.storage-sapbits[0].name
  container_access_type = local.sa_container_access_type
}

# Creates file share inside the storage account for SAP bits
resource "azurerm_storage_share" "fileshare-sapbits" {
  count                = local.sa_sapbits_exists ? 0 : (local.sa_file_share_name == "" ? 0 : 1)
  name                 = local.sa_file_share_name
  storage_account_name = azurerm_storage_account.storage-sapbits[0].name
}

# Imports existing storage account to use for SAP bits
data "azurerm_storage_account" "storage-sapbits" {
  count               = local.sa_sapbits_exists ? 1 : 0
  name                = split("/", var.software.storage_account_sapbits.arm_id)[8]
  resource_group_name = split("/", var.software.storage_account_sapbits.arm_id)[4]
}

# Creates boot diagnostics storage account
resource "azurerm_storage_account" "storage-bootdiag" {
  name                      = "sabootdiag${random_id.random-id.hex}"
  resource_group_name       = local.rg_exists ? data.azurerm_resource_group.resource-group[0].name : azurerm_resource_group.resource-group[0].name
  location                  = local.rg_exists ? data.azurerm_resource_group.resource-group[0].location : azurerm_resource_group.resource-group[0].location
  account_replication_type  = "LRS"
  account_tier              = "Standard"
  enable_https_traffic_only = var.options.enable_secure_transfer == "" ? true : var.options.enable_secure_transfer
}


# PROXIMITY PLACEMENT GROUP ===============================================================================================

resource "azurerm_proximity_placement_group" "ppg" {
  count               = local.ppg_exists ? 0 : 1
  name                = local.ppg_name
  resource_group_name = local.rg_exists ? data.azurerm_resource_group.resource-group[0].name : azurerm_resource_group.resource-group[0].name
  location            = local.rg_exists ? data.azurerm_resource_group.resource-group[0].location : azurerm_resource_group.resource-group[0].location
}


data "azurerm_proximity_placement_group" "ppg" {
  count               = local.ppg_exists ? 1 : 0
  name                = split("/", local.ppg_arm_id)[8]
  resource_group_name = split("/", local.ppg_arm_id)[4]
}
