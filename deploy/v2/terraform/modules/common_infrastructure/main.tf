##################################################################################################################
# RESOURCES
##################################################################################################################

# RESOURCE GROUP =================================================================================================

# Creates the resource group
resource "azurerm_resource_group" "rg" {
  count    = var.infrastructure.resource_group.is_existing ? 0 : 1
  name     = var.infrastructure.resource_group.name
  location = var.infrastructure.region
}

# VNETs ==========================================================================================================

# Creates the management VNET
resource "azurerm_virtual_network" "vnet-management" {
  count               = var.infrastructure.vnets.management.is_existing ? 0 : 1
  name                = var.infrastructure.vnets.management.name
  location            = var.infrastructure.region
  resource_group_name = var.infrastructure.resource_group.is_existing ? var.infrastructure.resource_group.name : azurerm_resource_group.rg[0].name
  address_space       = [var.infrastructure.vnets.management.address_space]
}

# Creates the SAP VNET
resource "azurerm_virtual_network" "vnet-sap" {
  count               = var.infrastructure.vnets.sap.is_existing ? 0 : 1
  name                = var.infrastructure.vnets.sap.name
  location            = var.infrastructure.region
  resource_group_name = var.infrastructure.resource_group.is_existing ? var.infrastructure.resource_group.name : azurerm_resource_group.rg[0].name
  address_space       = [var.infrastructure.vnets.sap.address_space]
}

# Imports data of existing management VNET
data "azurerm_virtual_network" "vnet-management" {
  count               = var.infrastructure.vnets.management.is_existing ? 1 : 0
  name                = var.infrastructure.vnets.management.name
  resource_group_name = var.infrastructure.resource_group.name
}

# Imports data of existing SAP VNET
data "azurerm_virtual_network" "vnet-sap" {
  count               = var.infrastructure.vnets.sap.is_existing ? 1 : 0
  name                = var.infrastructure.vnets.sap.name
  resource_group_name = var.infrastructure.resource_group.name
}

# SUBNETs ========================================================================================================

# Creates mgmt subnet of management VNET
resource "azurerm_subnet" "subnet-mgmt" {
  count                = var.infrastructure.vnets.management.subnet_mgmt.is_existing ? 0 : 1
  name                 = var.infrastructure.vnets.management.subnet_mgmt.name
  resource_group_name  = var.infrastructure.resource_group.is_existing ? var.infrastructure.resource_group.name : azurerm_resource_group.rg[0].name
  virtual_network_name = var.infrastructure.vnets.management.is_existing ? var.infrastructure.vnets.management.name : azurerm_virtual_network.vnet-management[0].name
  address_prefix       = var.infrastructure.vnets.management.subnet_mgmt.prefix
}

# Creates admin subnet of SAP VNET
resource "azurerm_subnet" "subnet-sap-admin" {
  count                = var.infrastructure.vnets.sap.subnet_admin.is_existing ? 0 : 1
  name                 = var.infrastructure.vnets.sap.subnet_admin.name
  resource_group_name  = var.infrastructure.resource_group.is_existing ? var.infrastructure.resource_group.name : azurerm_resource_group.rg[0].name
  virtual_network_name = var.infrastructure.vnets.sap.is_existing ? var.infrastructure.vnets.sap.name : azurerm_virtual_network.vnet-sap[0].name
  address_prefix       = var.infrastructure.vnets.sap.subnet_admin.prefix
}

# Creates client subnet of SAP VNET
resource "azurerm_subnet" "subnet-sap-client" {
  count                = var.infrastructure.vnets.sap.subnet_client.is_existing ? 0 : 1
  name                 = var.infrastructure.vnets.sap.subnet_client.name
  resource_group_name  = var.infrastructure.resource_group.is_existing ? var.infrastructure.resource_group.name : azurerm_resource_group.rg[0].name
  virtual_network_name = var.infrastructure.vnets.sap.is_existing ? var.infrastructure.vnets.sap.name : azurerm_virtual_network.vnet-sap[0].name
  address_prefix       = var.infrastructure.vnets.sap.subnet_client.prefix
}

# Creates app subnet of SAP VNET
resource "azurerm_subnet" "subnet-sap-app" {
  count                = var.is_single_node_hana ? 0 : lookup(var.infrastructure.sap, "subnet_app.is_existing", false) ? 0 : 1
  name                 = var.infrastructure.vnets.sap.subnet_app.name
  resource_group_name  = var.infrastructure.resource_group.is_existing ? var.infrastructure.resource_group.name : azurerm_resource_group.rg[0].name
  virtual_network_name = var.infrastructure.vnets.sap.is_existing ? var.infrastructure.vnets.sap.name : azurerm_virtual_network.vnet-sap[0].name
  address_prefix       = var.infrastructure.vnets.sap.subnet_app.prefix
}

# Imports data of existing mgmt subnet
data "azurerm_subnet" "subnet-mgmt" {
  count                = var.infrastructure.vnets.management.subnet_mgmt.is_existing ? 1 : 0
  name                 = var.infrastructure.vnets.management.subnet_mgmt.name
  resource_group_name  = var.infrastructure.resource_group.name
  virtual_network_name = var.infrastructure.vnets.management.name
}

# Imports data of existing SAP admin subnet
data "azurerm_subnet" "subnet-sap-admin" {
  count                = var.infrastructure.vnets.sap.subnet_admin.is_existing ? 1 : 0
  name                 = var.infrastructure.vnets.sap.subnet_admin.name
  resource_group_name  = var.infrastructure.resource_group.name
  virtual_network_name = var.infrastructure.vnets.sap.name
}

# Imports data of existing SAP client subnet
data "azurerm_subnet" "subnet-sap-client" {
  count                = var.infrastructure.vnets.sap.subnet_client.is_existing ? 1 : 0
  name                 = var.infrastructure.vnets.sap.subnet_client.name
  resource_group_name  = var.infrastructure.resource_group.name
  virtual_network_name = var.infrastructure.vnets.sap.name
}

# Imports data of existing SAP app subnet
data "azurerm_subnet" "subnet-sap-app" {
  count                = var.is_single_node_hana ? 0 : lookup(var.infrastructure.sap, "subnet_app.is_existing", false) ? 1 : 0
  name                 = var.infrastructure.vnets.sap.subnet_app.name
  resource_group_name  = var.infrastructure.resource_group.name
  virtual_network_name = var.infrastructure.vnets.sap.name
}


# NSGs ===========================================================================================================

# Creates mgmt subnet nsg
resource "azurerm_network_security_group" "nsg-mgmt" {
  count               = var.infrastructure.vnets.management.subnet_mgmt.nsg.is_existing ? 0 : 1
  name                = var.infrastructure.vnets.management.subnet_mgmt.nsg.name
  location            = var.infrastructure.region
  resource_group_name = var.infrastructure.resource_group.is_existing ? var.infrastructure.resource_group.name : azurerm_resource_group.rg[0].name
}

# Creates SAP admin subnet nsg
resource "azurerm_network_security_group" "nsg-admin" {
  count               = var.infrastructure.vnets.sap.subnet_admin.nsg.is_existing ? 0 : 1
  name                = var.infrastructure.vnets.sap.subnet_admin.nsg.name
  location            = var.infrastructure.region
  resource_group_name = var.infrastructure.resource_group.is_existing ? var.infrastructure.resource_group.name : azurerm_resource_group.rg[0].name
}

# Creates SAP client subnet nsg
resource "azurerm_network_security_group" "nsg-client" {
  count               = var.infrastructure.vnets.sap.subnet_client.nsg.is_existing ? 0 : 1
  name                = var.infrastructure.vnets.sap.subnet_client.nsg.name
  location            = var.infrastructure.region
  resource_group_name = var.infrastructure.resource_group.is_existing ? var.infrastructure.resource_group.name : azurerm_resource_group.rg[0].name
}

# Creates SAP app subnet nsg
resource "azurerm_network_security_group" "nsg-app" {
  count               = var.is_single_node_hana ? 0 : lookup(var.infrastructure.sap, "subnet_app.nsg.is_existing", false) ? 0 : 1
  name                = var.infrastructure.vnets.sap.subnet_app.nsg.name
  location            = var.infrastructure.region
  resource_group_name = var.infrastructure.resource_group.is_existing ? var.infrastructure.resource_group.name : azurerm_resource_group.rg[0].name
}

# Imports the mgmt subnet nsg data
data "azurerm_network_security_group" "nsg-mgmt" {
  count               = var.infrastructure.vnets.management.subnet_mgmt.nsg.is_existing ? 1 : 0
  name                = var.infrastructure.vnets.management.subnet_mgmt.nsg.name
  resource_group_name = var.infrastructure.resource_group.name
}

# Imports the SAP admin subnet nsg data
data "azurerm_network_security_group" "nsg-admin" {
  count               = var.infrastructure.vnets.sap.subnet_admin.nsg.is_existing ? 1 : 0
  name                = var.infrastructure.vnets.sap.subnet_admin.nsg.name
  resource_group_name = var.infrastructure.resource_group.name
}

# Imports the SAP client subnet nsg data
data "azurerm_network_security_group" "nsg-client" {
  count               = var.infrastructure.vnets.sap.subnet_client.nsg.is_existing ? 1 : 0
  name                = var.infrastructure.vnets.sap.subnet_client.nsg.name
  resource_group_name = var.infrastructure.resource_group.name
}

# Imports the SAP app subnet nsg data
data "azurerm_network_security_group" "nsg-app" {
  count               = var.is_single_node_hana ? 0 : lookup(var.infrastructure.sap, "subnet_app.nsg.is_existing", false) ? 1 : 0
  name                = var.infrastructure.vnets.sap.subnet_app.nsg.name
  resource_group_name = var.infrastructure.resource_group.name
}

# Associates mgmt nsg to mgmt subnet
resource "azurerm_subnet_network_security_group_association" "Associate-nsg-mgmt" {
  count                     = var.infrastructure.vnets.management.subnet_mgmt.nsg.is_existing ? 0 : 1
  subnet_id                 = var.infrastructure.vnets.management.subnet_mgmt.is_existing ? data.azurerm_subnet.subnet-mgmt[0].id : azurerm_subnet.subnet-mgmt[0].id
  network_security_group_id = var.infrastructure.vnets.management.subnet_mgmt.nsg.is_existing ? data.azurerm_network_security_group.nsg-mgmt[0].id : azurerm_network_security_group.nsg-mgmt[0].id
}

# Associates SAP admin nsg to SAP admin subnet
resource "azurerm_subnet_network_security_group_association" "Associate-nsg-admin" {
  count                     = var.infrastructure.vnets.sap.subnet_admin.nsg.is_existing ? 0 : 1
  subnet_id                 = var.infrastructure.vnets.sap.subnet_admin.is_existing ? data.azurerm_subnet.subnet-sap-admin[0].id : azurerm_subnet.subnet-sap-admin[0].id
  network_security_group_id = var.infrastructure.vnets.sap.subnet_admin.nsg.is_existing ? data.azurerm_network_security_group.nsg-admin[0].id : azurerm_network_security_group.nsg-admin[0].id
}

# Associates SAP client nsg to SAP client subnet
resource "azurerm_subnet_network_security_group_association" "Associate-nsg-client" {
  count                     = var.infrastructure.vnets.sap.subnet_client.nsg.is_existing ? 0 : 1
  subnet_id                 = var.infrastructure.vnets.sap.subnet_client.is_existing ? data.azurerm_subnet.subnet-sap-client[0].id : azurerm_subnet.subnet-sap-client[0].id
  network_security_group_id = var.infrastructure.vnets.sap.subnet_client.nsg.is_existing ? data.azurerm_network_security_group.nsg-client[0].id : azurerm_network_security_group.nsg-client[0].id
}

# Associates SAP app nsg to SAP app subnet
resource "azurerm_subnet_network_security_group_association" "Associate-nsg-app" {
  count                     = var.is_single_node_hana ? 0 : lookup(var.infrastructure.sap, "subnet_app.nsg.is_existing", false) ? 0 : 1
  subnet_id                 = var.infrastructure.vnets.sap.subnet_app.is_existing ? data.azurerm_subnet.subnet-sap-app[0].id : azurerm_subnet.subnet-sap-app[0].id
  network_security_group_id = var.infrastructure.vnets.sap.subnet_app.nsg.is_existing ? data.azurerm_network_security_group.nsg-app[0].id : azurerm_network_security_group.nsg-app[0].id
}

# VNET PEERINGs ==================================================================================================

# Peers management VNET to SAP VNET
resource "azurerm_virtual_network_peering" "peering-management-sap" {
  count                        = signum((var.infrastructure.vnets.management.is_existing ? 0 : 1) + (var.infrastructure.vnets.sap.is_existing ? 0 : 1))
  name                         = "${var.infrastructure.vnets.management.name}-${var.infrastructure.vnets.sap.name}"
  resource_group_name          = var.infrastructure.resource_group.name
  virtual_network_name         = var.infrastructure.vnets.management.is_existing ? var.infrastructure.vnets.management.name : azurerm_virtual_network.vnet-management[0].name
  remote_virtual_network_id    = var.infrastructure.vnets.sap.is_existing ? data.azurerm_virtual_network.vnet-sap[0].id : azurerm_virtual_network.vnet-sap[0].id
  allow_virtual_network_access = true
}

# Peers SAP VNET to management VNET
resource "azurerm_virtual_network_peering" "peering-sap-management" {
  count                        = signum((var.infrastructure.vnets.management.is_existing ? 0 : 1) + (var.infrastructure.vnets.sap.is_existing ? 0 : 1))
  name                         = "${var.infrastructure.vnets.sap.name}-${var.infrastructure.vnets.management.name}"
  resource_group_name          = var.infrastructure.resource_group.name
  virtual_network_name         = var.infrastructure.vnets.sap.is_existing ? var.infrastructure.vnets.sap.name : azurerm_virtual_network.vnet-sap[0].name
  remote_virtual_network_id    = var.infrastructure.vnets.management.is_existing ? data.azurerm_virtual_network.vnet-management[0].id : azurerm_virtual_network.vnet-management[0].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}
