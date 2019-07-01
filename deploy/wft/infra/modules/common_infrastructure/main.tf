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

# Creates the spoke db subnet
resource "azurerm_subnet" "demo-spoke-subnet" {
  depends_on	       = [azurerm_virtual_network.demo-spoke-vnet]
  name                 = var.az_spoke_db_subnet
  resource_group_name  = var.az_resource_group
  virtual_network_name = var.az_spoke_vnet
  address_prefix       = var.az_spoke_db_subnet_prefix
}

# Creates spoke db subnet nsg
resource "azurerm_network_security_group" "demo-spoke-db-subnet-nsg" {
  depends_on		= [azurerm_resource_group.demo-rg]
  name			= "spoke-db-subnet-nsg"
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

# Creates jumpbox nsg
resource "azurerm_network_security_group" "demo-jumpbox-nsg" {
  depends_on		= [azurerm_resource_group.demo-rg]
  name			= "${var.az_vm}-nsg"
  location		= var.az_region
  resource_group_name	= var.az_resource_group
}

# Creates jumpbox rdp network security rule
resource "azurerm_network_security_rule" "demo-jumpbox-nsr1" {
  depends_on				= [azurerm_network_security_group.demo-jumpbox-nsg]
  name					= "rdp"
  resource_group_name			= var.az_resource_group
  network_security_group_name		= azurerm_network_security_group.demo-jumpbox-nsg.name
  priority				= 101
  direction				= "Inbound"
  access				= "allow"
  protocol				= "Tcp"
  source_port_range			= "*"
  destination_port_range		= 3389
  source_address_prefix			= "*"
  destination_address_prefix		= "*"
}

# Creates jumpbox ssh network security rule
resource "azurerm_network_security_rule" "demo-jumpbox-nsr2" {
  depends_on				= [azurerm_network_security_group.demo-jumpbox-nsg]
  name					= "ssh"
  resource_group_name			= var.az_resource_group
  network_security_group_name		= azurerm_network_security_group.demo-jumpbox-nsg.name
  priority				= 102
  direction				= "Inbound"
  access				= "allow"
  protocol				= "Tcp"
  source_port_range			= "*"
  destination_port_range		= 22
  source_address_prefix			= "*"
  destination_address_prefix		= "*"
}

# Creates the jumpbox nic and ip
resource "azurerm_network_interface" "demo-jumpbox-nic1" {
  name 					= "${var.az_vm}-nic1"
  location				= var.az_region
  resource_group_name			= var.az_resource_group
  network_security_group_id		= azurerm_network_security_group.demo-jumpbox-nsg.id

  ip_configuration {
    name				= "${var.az_vm}-nic1-ip"
    subnet_id				= azurerm_subnet.demo-hub-subnet.id
    private_ip_address			= var.az_jumpbox_private_ip_address
    private_ip_address_allocation	= "static"		
  }
} 


# Create jumpbox vm
resource "azurerm_virtual_machine" "demo-jumpbox-vm" {
  name                          = var.az_vm
  location                      = var.az_region
  resource_group_name           = var.az_resource_group
  network_interface_ids         = [azurerm_network_interface.demo-jumpbox-nic1.id]
  vm_size                       = "Standard_D4s_v3"
  delete_os_disk_on_termination = "true"

  storage_os_disk {
    name              = "${var.az_vm}-OsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "SUSE"
    offer     = "SLES-SAP"
    sku       = "12-SP3"
    version   = "latest"
  }

  os_profile {
    computer_name  = var.az_vm
    admin_username = "azureadmin"
    admin_password = "S@phana1234!"
  }

os_profile_linux_config {
    disable_password_authentication = false
  }

  boot_diagnostics {
    enabled = "true"

    storage_uri = azurerm_storage_account.demo-bootdiag-storageaccount.primary_blob_endpoint
  }
}
