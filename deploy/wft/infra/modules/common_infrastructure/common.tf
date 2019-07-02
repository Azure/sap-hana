# Creates the resource group
resource "azurerm_resource_group" "demo-rg"{
  name		= var.az_resource_group
  location	= var.az_region
}

# Creates the hub vnet
resource "azurerm_virtual_network" "demo-hub-vnet" {
  depends_on	        = [azurerm_resource_group.demo-rg]
  name			= var.az_hub_vnet
  location		= var.az_region
  resource_group_name	= var.az_resource_group
  address_space		= [var.az_hub_address_space]
}

# Creates the hub subnet
resource "azurerm_subnet" "demo-hub-subnet" {
  depends_on	       = [azurerm_virtual_network.demo-hub-vnet]
  name                 = var.az_hub_subnet
  resource_group_name  = var.az_resource_group
  virtual_network_name = var.az_hub_vnet
  address_prefix       = var.az_hub_subnet_prefix
}

# Creates the spoke vnet
resource "azurerm_virtual_network" "demo-spoke-vnet" {
  depends_on	        = [azurerm_resource_group.demo-rg]
  name			= var.az_spoke_vnet
  location		= var.az_region
  resource_group_name	= var.az_resource_group
  address_space		= [var.az_spoke_address_space]
}

# Creates the spoke db client subnet
resource "azurerm_subnet" "demo-spoke-db-client-subnet" {
  depends_on	       = [azurerm_virtual_network.demo-spoke-vnet]
  name                 = var.az_spoke_db_client_subnet
  resource_group_name  = var.az_resource_group
  virtual_network_name = var.az_spoke_vnet
  address_prefix       = var.az_spoke_db_client_subnet_prefix
}

# Creates spoke db client subnet nsg
resource "azurerm_network_security_group" "demo-spoke-db-client-subnet-nsg" {
  depends_on		= [azurerm_resource_group.demo-rg]
  name			= "spoke-db-client-subnet-nsg"
  location		= var.az_region
  resource_group_name	= var.az_resource_group
}

# Creates the spoke db admin subnet
resource "azurerm_subnet" "demo-spoke-db-admin-subnet" {
  depends_on	       = [azurerm_virtual_network.demo-spoke-vnet]
  name                 = var.az_spoke_db_admin_subnet
  resource_group_name  = var.az_resource_group
  virtual_network_name = var.az_spoke_vnet
  address_prefix       = var.az_spoke_db_admin_subnet_prefix
}

# Creates spoke db admin subnet nsg
resource "azurerm_network_security_group" "demo-spoke-db-admin-subnet-nsg" {
  depends_on		= [azurerm_resource_group.demo-rg]
  name			= "spoke-db-admin-subnet-nsg"
  location		= var.az_region
  resource_group_name	= var.az_resource_group
}

# Peers hub vnet to spoke vnet
resource "azurerm_virtual_network_peering" "demo-peer-hub-spoke" {
  depends_on		    = [azurerm_virtual_network.demo-hub-vnet, azurerm_virtual_network.demo-spoke-vnet]
  name                      = "hub-to-spoke-peering"
  resource_group_name       = var.az_resource_group
  virtual_network_name      = var.az_hub_vnet
  remote_virtual_network_id = azurerm_virtual_network.demo-spoke-vnet.id
}

# peers spoke vnet to hub vnet
resource "azurerm_virtual_network_peering" "demo-peer-spoke-hub" {
  depends_on		    = [azurerm_virtual_network.demo-hub-vnet, azurerm_virtual_network.demo-spoke-vnet] 
  name                      = "spoke-to-hub-peering"
  resource_group_name       = var.az_resource_group
  virtual_network_name      = var.az_spoke_vnet
  remote_virtual_network_id = azurerm_virtual_network.demo-hub-vnet.id
}

# Generate random text for a unique boot diagnostics storage account name.
resource "random_id" "randomId" {
  depends_on	        = [azurerm_resource_group.demo-rg]
  keepers = {
    # Generate a new id only when a new resource group is defined.
    resource_group = var.az_resource_group
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "demo-bootdiag-storageaccount" {
  depends_on	           = [azurerm_resource_group.demo-rg]
  name                     = "diag${random_id.randomId.hex}"
  resource_group_name      = var.az_resource_group
  location                 = var.az_region
  account_tier             = "Standard"
  account_replication_type = "LRS"
}


