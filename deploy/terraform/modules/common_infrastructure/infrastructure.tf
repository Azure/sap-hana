##################################################################################################################
# RESOURCES
##################################################################################################################

# RESOURCE GROUP =================================================================================================

# Creates the resource group
resource "azurerm_resource_group" "resource-group" {
<<<<<<< HEAD
  count    = local.rg_exists ? 0 : 1
  name     = local.rg_name
  location = local.region
=======
  count    = var.infrastructure.resource_group.is_existing ? 0 : 1
  name     = var.infrastructure.resource_group.name
  location = var.infrastructure.region
>>>>>>> Revert "Delete infrastructure.tf"
}

# Imports data of existing resource group
data "azurerm_resource_group" "resource-group" {
<<<<<<< HEAD
  count = local.rg_exists ? 1 : 0
  name  = split("/", local.rg_arm_id)[4]
=======
  count = var.infrastructure.resource_group.is_existing ? 1 : 0
  name  = split("/", var.infrastructure.resource_group.arm_id)[4]
>>>>>>> Revert "Delete infrastructure.tf"
}

# VNETs ==========================================================================================================

# Creates the management VNET
resource "azurerm_virtual_network" "vnet-management" {
<<<<<<< HEAD
  count               = local.vnet_mgmt_exists ? 0 : 1
  name                = local.vnet_mgmt_name
  location            = local.rg_exists ? data.azurerm_resource_group.resource-group[0].location : azurerm_resource_group.resource-group[0].location
  resource_group_name = local.rg_exists ? data.azurerm_resource_group.resource-group[0].name : azurerm_resource_group.resource-group[0].name
  address_space       = [local.vnet_mgmt_addr]
=======
  count               = var.infrastructure.vnets.management.is_existing ? 0 : 1
  name                = var.infrastructure.vnets.management.name
  location            = var.infrastructure.resource_group.is_existing ? data.azurerm_resource_group.resource-group[0].location : azurerm_resource_group.resource-group[0].location
  resource_group_name = var.infrastructure.resource_group.is_existing ? data.azurerm_resource_group.resource-group[0].name : azurerm_resource_group.resource-group[0].name
  address_space       = [var.infrastructure.vnets.management.address_space]
>>>>>>> Revert "Delete infrastructure.tf"
}

# Creates the SAP VNET
resource "azurerm_virtual_network" "vnet-sap" {
<<<<<<< HEAD
  count               = local.vnet_sap_exists ? 0 : 1
  name                = local.vnet_sap_name
  location            = local.rg_exists ? data.azurerm_resource_group.resource-group[0].location : azurerm_resource_group.resource-group[0].location
  resource_group_name = local.rg_exists ? data.azurerm_resource_group.resource-group[0].name : azurerm_resource_group.resource-group[0].name
  address_space       = [local.vnet_sap_addr]
=======
  count               = var.infrastructure.vnets.sap.is_existing ? 0 : 1
  name                = var.infrastructure.vnets.sap.name
  location            = var.infrastructure.resource_group.is_existing ? data.azurerm_resource_group.resource-group[0].location : azurerm_resource_group.resource-group[0].location
  resource_group_name = var.infrastructure.resource_group.is_existing ? data.azurerm_resource_group.resource-group[0].name : azurerm_resource_group.resource-group[0].name
  address_space       = [var.infrastructure.vnets.sap.address_space]
>>>>>>> Revert "Delete infrastructure.tf"
}

# Imports data of existing management VNET
data "azurerm_virtual_network" "vnet-management" {
<<<<<<< HEAD
  count               = local.vnet_mgmt_exists ? 1 : 0
  name                = split("/", local.vnet_mgmt_arm_id)[8]
  resource_group_name = split("/", local.vnet_mgmt_arm_id)[4]
=======
  count               = var.infrastructure.vnets.management.is_existing ? 1 : 0
  name                = split("/", var.infrastructure.vnets.management.arm_id)[8]
  resource_group_name = split("/", var.infrastructure.vnets.management.arm_id)[4]
>>>>>>> Revert "Delete infrastructure.tf"
}

# Imports data of existing SAP VNET
data "azurerm_virtual_network" "vnet-sap" {
<<<<<<< HEAD
  count               = local.vnet_sap_exists ? 1 : 0
  name                = split("/", local.vnet_sap_arm_id)[8]
  resource_group_name = split("/", local.vnet_sap_arm_id)[4]
=======
  count               = var.infrastructure.vnets.sap.is_existing ? 1 : 0
  name                = split("/", var.infrastructure.vnets.sap.arm_id)[8]
  resource_group_name = split("/", var.infrastructure.vnets.sap.arm_id)[4]
>>>>>>> Revert "Delete infrastructure.tf"
}

# SUBNETs ========================================================================================================

# Creates mgmt subnet of management VNET
resource "azurerm_subnet" "subnet-mgmt" {
<<<<<<< HEAD
  count                = local.sub_mgmt_exists ? 0 : 1
  name                 = local.sub_mgmt_name
  resource_group_name  = local.vnet_mgmt_exists ? data.azurerm_virtual_network.vnet-management[0].resource_group_name : azurerm_virtual_network.vnet-management[0].resource_group_name
  virtual_network_name = local.vnet_mgmt_exists ? data.azurerm_virtual_network.vnet-management[0].name : azurerm_virtual_network.vnet-management[0].name
  address_prefixes     = [local.sub_mgmt_prefix]
=======
  count                = var.infrastructure.vnets.management.subnet_mgmt.is_existing ? 0 : 1
  name                 = var.infrastructure.vnets.management.subnet_mgmt.name
  resource_group_name  = var.infrastructure.vnets.management.is_existing ? data.azurerm_virtual_network.vnet-management[0].resource_group_name : azurerm_virtual_network.vnet-management[0].resource_group_name
  virtual_network_name = var.infrastructure.vnets.management.is_existing ? data.azurerm_virtual_network.vnet-management[0].name : azurerm_virtual_network.vnet-management[0].name
  address_prefixes     = [var.infrastructure.vnets.management.subnet_mgmt.prefix]
>>>>>>> Revert "Delete infrastructure.tf"
}

# Imports data of existing mgmt subnet
data "azurerm_subnet" "subnet-mgmt" {
<<<<<<< HEAD
  count                = local.sub_mgmt_exists ? 1 : 0
  name                 = split("/", local.sub_mgmt_arm_id)[10]
  resource_group_name  = split("/", local.sub_mgmt_arm_id)[4]
  virtual_network_name = split("/", local.sub_mgmt_arm_id)[8]
=======
  count                = var.infrastructure.vnets.management.subnet_mgmt.is_existing ? 1 : 0
  name                 = split("/", var.infrastructure.vnets.management.subnet_mgmt.arm_id)[10]
  resource_group_name  = split("/", var.infrastructure.vnets.management.subnet_mgmt.arm_id)[4]
  virtual_network_name = split("/", var.infrastructure.vnets.management.subnet_mgmt.arm_id)[8]
>>>>>>> Revert "Delete infrastructure.tf"
}

# Associates mgmt nsg to mgmt subnet
resource "azurerm_subnet_network_security_group_association" "Associate-nsg-mgmt" {
<<<<<<< HEAD
  count                     = signum((local.vnet_mgmt_exists ? 0 : 1) + (local.sub_mgmt_nsg_exists ? 0 : 1))
  subnet_id                 = local.sub_mgmt_exists ? data.azurerm_subnet.subnet-mgmt[0].id : azurerm_subnet.subnet-mgmt[0].id
  network_security_group_id = local.sub_mgmt_nsg_exists ? data.azurerm_network_security_group.nsg-mgmt[0].id : azurerm_network_security_group.nsg-mgmt[0].id
=======
  count                     = signum((var.infrastructure.vnets.management.is_existing ? 0 : 1) + (var.infrastructure.vnets.management.subnet_mgmt.nsg.is_existing ? 0 : 1))
  subnet_id                 = var.infrastructure.vnets.management.subnet_mgmt.is_existing ? data.azurerm_subnet.subnet-mgmt[0].id : azurerm_subnet.subnet-mgmt[0].id
  network_security_group_id = var.infrastructure.vnets.management.subnet_mgmt.nsg.is_existing ? data.azurerm_network_security_group.nsg-mgmt[0].id : azurerm_network_security_group.nsg-mgmt[0].id
>>>>>>> Revert "Delete infrastructure.tf"
}

# VNET PEERINGs ==================================================================================================

# Peers management VNET to SAP VNET
resource "azurerm_virtual_network_peering" "peering-management-sap" {
<<<<<<< HEAD
  count                        = signum((local.vnet_mgmt_exists ? 0 : 1) + (local.vnet_sap_exists ? 0 : 1))
  name                         = substr("${local.vnet_mgmt_exists ? data.azurerm_virtual_network.vnet-management[0].resource_group_name : azurerm_virtual_network.vnet-management[0].resource_group_name}_${local.vnet_mgmt_exists ? data.azurerm_virtual_network.vnet-management[0].name : azurerm_virtual_network.vnet-management[0].name}-${local.vnet_sap_exists ? data.azurerm_virtual_network.vnet-sap[0].resource_group_name : azurerm_virtual_network.vnet-sap[0].resource_group_name}_${local.vnet_sap_exists ? data.azurerm_virtual_network.vnet-sap[0].name : azurerm_virtual_network.vnet-sap[0].name}", 0, 80)
  resource_group_name          = local.vnet_mgmt_exists ? data.azurerm_virtual_network.vnet-management[0].resource_group_name : azurerm_virtual_network.vnet-management[0].resource_group_name
  virtual_network_name         = local.vnet_mgmt_exists ? data.azurerm_virtual_network.vnet-management[0].name : azurerm_virtual_network.vnet-management[0].name
  remote_virtual_network_id    = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet-sap[0].id : azurerm_virtual_network.vnet-sap[0].id
=======
  count                        = signum((var.infrastructure.vnets.management.is_existing ? 0 : 1) + (var.infrastructure.vnets.sap.is_existing ? 0 : 1))
  name                         = local.peeringNameSap
  resource_group_name          = var.infrastructure.vnets.management.is_existing ? data.azurerm_virtual_network.vnet-management[0].resource_group_name : azurerm_virtual_network.vnet-management[0].resource_group_name
  virtual_network_name         = var.infrastructure.vnets.management.is_existing ? data.azurerm_virtual_network.vnet-management[0].name : azurerm_virtual_network.vnet-management[0].name
  remote_virtual_network_id    = var.infrastructure.vnets.sap.is_existing ? data.azurerm_virtual_network.vnet-sap[0].id : azurerm_virtual_network.vnet-sap[0].id
>>>>>>> Revert "Delete infrastructure.tf"
  allow_virtual_network_access = true
}

# Peers SAP VNET to management VNET
resource "azurerm_virtual_network_peering" "peering-sap-management" {
<<<<<<< HEAD
  count                        = signum((local.vnet_mgmt_exists ? 0 : 1) + (local.vnet_sap_exists ? 0 : 1))
  name                         = substr("${local.vnet_sap_exists ? data.azurerm_virtual_network.vnet-sap[0].resource_group_name : azurerm_virtual_network.vnet-sap[0].resource_group_name}_${local.vnet_sap_exists ? data.azurerm_virtual_network.vnet-sap[0].name : azurerm_virtual_network.vnet-sap[0].name}-${local.vnet_mgmt_exists ? data.azurerm_virtual_network.vnet-management[0].resource_group_name : azurerm_virtual_network.vnet-management[0].resource_group_name}_${local.vnet_mgmt_exists ? data.azurerm_virtual_network.vnet-management[0].name : azurerm_virtual_network.vnet-management[0].name}", 0, 80)
  resource_group_name          = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet-sap[0].resource_group_name : azurerm_virtual_network.vnet-sap[0].resource_group_name
  virtual_network_name         = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet-sap[0].name : azurerm_virtual_network.vnet-sap[0].name
  remote_virtual_network_id    = local.vnet_mgmt_exists ? data.azurerm_virtual_network.vnet-management[0].id : azurerm_virtual_network.vnet-management[0].id
=======
  count                        = signum((var.infrastructure.vnets.management.is_existing ? 0 : 1) + (var.infrastructure.vnets.sap.is_existing ? 0 : 1))
  name                         = local.peeringNameManagement
  resource_group_name          = var.infrastructure.vnets.sap.is_existing ? data.azurerm_virtual_network.vnet-sap[0].resource_group_name : azurerm_virtual_network.vnet-sap[0].resource_group_name
  virtual_network_name         = var.infrastructure.vnets.sap.is_existing ? data.azurerm_virtual_network.vnet-sap[0].name : azurerm_virtual_network.vnet-sap[0].name
  remote_virtual_network_id    = var.infrastructure.vnets.management.is_existing ? data.azurerm_virtual_network.vnet-management[0].id : azurerm_virtual_network.vnet-management[0].id
>>>>>>> Revert "Delete infrastructure.tf"
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# STORAGE ACCOUNTS ===============================================================================================

# Generates random text for boot diagnostics storage account name
resource "random_id" "random-id" {
  keepers = {
    # Generate a new id only when a new resource group is defined
<<<<<<< HEAD
    resource_group = local.rg_exists ? data.azurerm_resource_group.resource-group[0].name : azurerm_resource_group.resource-group[0].name
=======
    resource_group = var.infrastructure.resource_group.is_existing ? data.azurerm_resource_group.resource-group[0].name : azurerm_resource_group.resource-group[0].name
>>>>>>> Revert "Delete infrastructure.tf"
  }
  byte_length = 4
}

# Creates storage account for storing SAP Bits
resource "azurerm_storage_account" "storage-sapbits" {
<<<<<<< HEAD
  count                     = local.sa_sapbits_exists ? 0 : 1
  name                      = local.sa_name
  resource_group_name       = local.rg_exists ? data.azurerm_resource_group.resource-group[0].name : azurerm_resource_group.resource-group[0].name
  location                  = local.rg_exists ? data.azurerm_resource_group.resource-group[0].location : azurerm_resource_group.resource-group[0].location
  account_replication_type  = "LRS"
  account_tier              = local.sa_account_tier
  account_kind              = local.sa_account_kind
=======
  count                     = var.software.storage_account_sapbits.is_existing ? 0 : 1
  name                      = lookup(var.software.storage_account_sapbits, "name", false) ? var.software.storage_account_sapbits.name : "sapbits${random_id.random-id.hex}"
  resource_group_name       = var.infrastructure.resource_group.is_existing ? data.azurerm_resource_group.resource-group[0].name : azurerm_resource_group.resource-group[0].name
  location                  = var.infrastructure.resource_group.is_existing ? data.azurerm_resource_group.resource-group[0].location : azurerm_resource_group.resource-group[0].location
  account_replication_type  = "LRS"
  account_tier              = var.software.storage_account_sapbits.account_tier
  account_kind              = var.software.storage_account_sapbits.account_kind
>>>>>>> Revert "Delete infrastructure.tf"
  enable_https_traffic_only = var.options.enable_secure_transfer == "" ? true : var.options.enable_secure_transfer
}

# Creates the storage container inside the storage account for SAP bits
resource "azurerm_storage_container" "storagecontainer-sapbits" {
<<<<<<< HEAD
  count                 = local.sa_sapbits_exists ? 0 : (local.sa_blob_container_name == "null" ? 0 : 1)
  name                  = local.sa_blob_container_name
  storage_account_name  = azurerm_storage_account.storage-sapbits[0].name
  container_access_type = local.sa_container_access_type
=======
  count                 = lookup(var.software.storage_account_sapbits, "blob_container_name", false) == false ? 0 : var.software.storage_account_sapbits.is_existing ? 0 : 1
  name                  = var.software.storage_account_sapbits.blob_container_name
  storage_account_name  = azurerm_storage_account.storage-sapbits[0].name
  container_access_type = var.software.storage_account_sapbits.container_access_type
>>>>>>> Revert "Delete infrastructure.tf"
}

# Creates file share inside the storage account for SAP bits
resource "azurerm_storage_share" "fileshare-sapbits" {
<<<<<<< HEAD
  count                = local.sa_sapbits_exists ? 0 : (local.sa_file_share_name == "" ? 0 : 1)
  name                 = local.sa_file_share_name
=======
  count                = lookup(var.software.storage_account_sapbits, "file_share_name", false) == false ? 0 : var.software.storage_account_sapbits.is_existing ? 0 : 1
  name                 = var.software.storage_account_sapbits.file_share_name
>>>>>>> Revert "Delete infrastructure.tf"
  storage_account_name = azurerm_storage_account.storage-sapbits[0].name
}

# Imports existing storage account to use for SAP bits
data "azurerm_storage_account" "storage-sapbits" {
<<<<<<< HEAD
  count               = local.sa_sapbits_exists ? 1 : 0
=======
  count               = var.software.storage_account_sapbits.is_existing ? 1 : 0
>>>>>>> Revert "Delete infrastructure.tf"
  name                = split("/", var.software.storage_account_sapbits.arm_id)[8]
  resource_group_name = split("/", var.software.storage_account_sapbits.arm_id)[4]
}

# Creates boot diagnostics storage account
resource "azurerm_storage_account" "storage-bootdiag" {
<<<<<<< HEAD
  name                      = "sabootdiag${random_id.random-id.hex}"
  resource_group_name       = local.rg_exists ? data.azurerm_resource_group.resource-group[0].name : azurerm_resource_group.resource-group[0].name
  location                  = local.rg_exists ? data.azurerm_resource_group.resource-group[0].location : azurerm_resource_group.resource-group[0].location
=======
  name                      = lookup(var.infrastructure, "boot_diagnostics_account_name", false) == false ? "sabootdiag${random_id.random-id.hex}" : var.infrastructure.boot_diagnostics_account_name
  resource_group_name       = var.infrastructure.resource_group.is_existing ? data.azurerm_resource_group.resource-group[0].name : azurerm_resource_group.resource-group[0].name
  location                  = var.infrastructure.resource_group.is_existing ? data.azurerm_resource_group.resource-group[0].location : azurerm_resource_group.resource-group[0].location
>>>>>>> Revert "Delete infrastructure.tf"
  account_replication_type  = "LRS"
  account_tier              = "Standard"
  enable_https_traffic_only = var.options.enable_secure_transfer == "" ? true : var.options.enable_secure_transfer
}


# PROXIMITY PLACEMENT GROUP ===============================================================================================

resource "azurerm_proximity_placement_group" "ppg" {
<<<<<<< HEAD
  count               = local.ppg_exists ? 0 : 1
  name                = local.ppg_name
  resource_group_name = local.rg_exists ? data.azurerm_resource_group.resource-group[0].name : azurerm_resource_group.resource-group[0].name
  location            = local.rg_exists ? data.azurerm_resource_group.resource-group[0].location : azurerm_resource_group.resource-group[0].location
=======
  count               = lookup(var.infrastructure, "ppg", false) != false ? (var.infrastructure.ppg.is_existing ? 0 : 1) : 0
  name                = var.infrastructure.ppg.name
  resource_group_name = var.infrastructure.resource_group.is_existing ? data.azurerm_resource_group.resource-group[0].name : azurerm_resource_group.resource-group[0].name
  location            = var.infrastructure.resource_group.is_existing ? data.azurerm_resource_group.resource-group[0].location : azurerm_resource_group.resource-group[0].location
>>>>>>> Revert "Delete infrastructure.tf"
}


data "azurerm_proximity_placement_group" "ppg" {
<<<<<<< HEAD
  count               = local.ppg_exists ? 1 : 0
  name                = split("/", local.ppg_arm_id)[8]
  resource_group_name = split("/", local.ppg_arm_id)[4]
=======
  count               = lookup(var.infrastructure, "ppg", false) != false ? (var.infrastructure.ppg.is_existing ? 1 : 0) : 0
  name                = split("/", var.infrastructure.ppg.arm_id)[8]
  resource_group_name = split("/", var.infrastructure.ppg.arm_id)[4]
>>>>>>> Revert "Delete infrastructure.tf"
}
