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
  enable_accelerated_networking		= "true"

  ip_configuration {
    name				= "${var.az_vm}-nic1-ip"
    subnet_id				= azurerm_subnet.demo-hub-subnet.id
    private_ip_address			= var.az_jumpbox_private_ip_address
    private_ip_address_allocation	= "static"		
  }
} 


# Creates Linux jumpbox vm
resource "azurerm_virtual_machine" "demo-jumpbox-linux-vm" {
  count				= var.az_jumpbox_os == "linux" ? 1 : 0
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
    managed_disk_type = "StandardSSD_LRS"
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

# Creates Windows jumpbox vm
resource "azurerm_virtual_machine" "demo-jumpbox-windows-vm" {
  count				= var.az_jumpbox_os == "windows" ? 1 : 0
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
    managed_disk_type = "StandardSSD_LRS"
  }

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  os_profile {
    computer_name  = var.az_vm
    admin_username = "azureadmin"
    admin_password = "S@phana1234!"
  }

  os_profile_windows_config {

  }

  boot_diagnostics {
    enabled = "true"

    storage_uri = azurerm_storage_account.demo-bootdiag-storageaccount.primary_blob_endpoint
  }
}
