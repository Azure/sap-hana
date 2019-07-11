# Creates the resource group
resource "azurerm_resource_group" "rg"{
  name = var.az_resource_group_name
  location = var.az_region
}

# Creates the management vnet
resource "azurerm_virtual_network" "mgmt-vnet" {
  depends_on	        = [azurerm_resource_group.rg]
  name			= var.az_mgmt_vnet_name
  location		= var.az_region
  resource_group_name	= azurerm_resource_group.rg.name
  address_space		= [var.az_mgmt_vnet_address_space]
}

# Creates the management subnet
resource "azurerm_subnet" "mgmt-subnet" {
  depends_on	       = [azurerm_virtual_network.mgmt-vnet]
  name                 = var.az_mgmt_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = var.az_mgmt_vnet_name
  address_prefix       = var.az_mgmt_subnet_prefix
}

# Creates the hana vnet
resource "azurerm_virtual_network" "hana-vnet" {
  depends_on	        = [azurerm_resource_group.rg]
  name			= var.az_hana_vnet_name
  location		= var.az_region
  resource_group_name	= azurerm_resource_group.rg.name
  address_space		= [var.az_hana_vnet_address_space]
}

# Creates the hana client subnet
resource "azurerm_subnet" "hana-client-subnet" {
  depends_on	       = [azurerm_virtual_network.hana-vnet]
  name                 = var.az_hana_client_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = var.az_hana_vnet_name
  address_prefix       = var.az_hana_client_subnet_prefix
}

# Creates the hana admin subnet
resource "azurerm_subnet" "hana-admin-subnet" {
  depends_on	       = [azurerm_virtual_network.hana-vnet]
  name                 = var.az_hana_admin_subnet_name
  resource_group_name  =  azurerm_resource_group.rg.name
  virtual_network_name = var.az_hana_vnet_name
  address_prefix       = var.az_hana_admin_subnet_prefix
}

# Creates hana client subnet nsg
resource "azurerm_network_security_group" "hana-client-subnet-nsg" {
  depends_on		= [azurerm_resource_group.rg]
  name			= "${var.az_hana_client_subnet_name}-nsg"
  location		= var.az_region
  resource_group_name	=azurerm_resource_group.rg.name
}

# Creates hana admin subnet nsg
resource "azurerm_network_security_group" "hana-admin-subnet-nsg" {
  depends_on		= [azurerm_resource_group.rg]
  name			= "${var.az_hana_admin_subnet_name}-nsg"
  location		= var.az_region
  resource_group_name	= azurerm_resource_group.rg.name
}

# Peers management vnet to hana vnet
resource "azurerm_virtual_network_peering" "mgmt-hana-vnet-peering" {
  depends_on		    = [azurerm_virtual_network.mgmt-vnet]
  name                      = "${var.az_mgmt_vnet_name}-${var.az_hana_vnet_name}-peering"
  resource_group_name       =  azurerm_resource_group.rg.name
  virtual_network_name      = var.az_mgmt_vnet_name
  remote_virtual_network_id = azurerm_virtual_network.hana-vnet.id
}

# peers hana vnet to management vnet
resource "azurerm_virtual_network_peering" "hana-mgmt-vnet-peering" {
  depends_on		    = [azurerm_virtual_network.hana-vnet] 
  name                      = "${var.az_hana_vnet_name}-${var.az_mgmt_vnet_name}-peering"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = var.az_hana_vnet_name
  remote_virtual_network_id = azurerm_virtual_network.mgmt-vnet.id
}

# Generates random text for a unique boot diagnostics storage account name.
resource "random_id" "random-id" {
  depends_on	        = [azurerm_resource_group.rg]
  keepers = {
    # Generates a new id only when a new resource group is defined.
    resource_group = var.az_resource_group_name
  }

  byte_length = 8
}

# Creates storage account for boot diagnostics
resource "azurerm_storage_account" "bootdiag-storageaccount" {
  depends_on	           = [azurerm_resource_group.rg]
  name                     = "diag${random_id.random-id.hex}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.az_region
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
