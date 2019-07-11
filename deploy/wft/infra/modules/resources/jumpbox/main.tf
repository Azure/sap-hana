# Creates jumpbox nsg
resource "azurerm_network_security_group" "jumpbox-nsg" {
  depends_on		= [var.az_resource_group]
  name			= "jumpbox-nsg"
  location		= var.az_region
  resource_group_name	= var.az_resource_group.name
}

# Creates jumpbox rdp network security rule
resource "azurerm_network_security_rule" "jumpbox-nsr1" {
  depends_on				= [azurerm_network_security_group.jumpbox-nsg]
  name					= "rdp"
  resource_group_name			= var.az_resource_group.name
  network_security_group_name		= azurerm_network_security_group.jumpbox-nsg.name
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
resource "azurerm_network_security_rule" "jumpbox-nsr2" {
  depends_on				= [azurerm_network_security_group.jumpbox-nsg]
  name					= "ssh"
  resource_group_name			= var.az_resource_group.name
  network_security_group_name		= azurerm_network_security_group.jumpbox-nsg.name
  priority				= 102
  direction				= "Inbound"
  access				= "allow"
  protocol				= "Tcp"
  source_port_range			= "*"
  destination_port_range		= 22
  source_address_prefix			= "*"
  destination_address_prefix		= "*"
}

# Creates the linux jumpbox nic and ip
resource "azurerm_network_interface" "linux-jumpbox-nic1" {
  count					= var.az_linux_jumpbox.required ? 1 : 0
  name 					= "${var.az_linux_jumpbox.name}-nic1"
  location				= var.az_region
  resource_group_name			= var.az_resource_group.name
  network_security_group_id		= azurerm_network_security_group.jumpbox-nsg.id
  enable_accelerated_networking		= "true"

  ip_configuration {
    name				= "${var.az_linux_jumpbox.name}-nic1-ip"
    subnet_id				= var.az_mgmt_subnet.id
    private_ip_address			= var.az_linux_jumpbox.private_ip_address
    private_ip_address_allocation	= "static"		
  }
}
 
# Creates the windows jumpbox nic and ip
resource "azurerm_network_interface" "windows-jumpbox-nic1" {
  count					= var.az_windows_jumpbox.required ? 1 : 0
  name 					= "${var.az_windows_jumpbox.name}-nic1"
  location				= var.az_region
  resource_group_name			= var.az_resource_group.name
  network_security_group_id		= azurerm_network_security_group.jumpbox-nsg.id
  enable_accelerated_networking		= "true"

  ip_configuration {
    name				= "${var.az_windows_jumpbox.name}-nic1-ip"
    subnet_id				= var.az_mgmt_subnet.id
    private_ip_address			= var.az_windows_jumpbox.private_ip_address
    private_ip_address_allocation	= "static"		
  }
}

# Creates Linux jumpbox vm
resource "azurerm_virtual_machine" "linux-jumpbox-vm" {
  count				= var.az_linux_jumpbox.required ? 1 : 0
  name                          = var.az_linux_jumpbox.name
  location                      = var.az_region
  resource_group_name           = var.az_resource_group.name
  network_interface_ids         = [azurerm_network_interface.linux-jumpbox-nic1[0].id]
  vm_size                       = "Standard_D4s_v3"
  delete_os_disk_on_termination = "true"

  storage_os_disk {
    name              = "${var.az_linux_jumpbox.name}-osdisk"
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
    computer_name  = var.az_linux_jumpbox.name
    admin_username = "${var.az_linux_jumpbox.username}"
    admin_password = "${var.az_linux_jumpbox.password}"
  }

os_profile_linux_config {
    disable_password_authentication = false
  }

  boot_diagnostics {
    enabled = "true"

    storage_uri = var.az_bootdiag_sa.primary_blob_endpoint
  }
}

# Creates Windows jumpbox vm
resource "azurerm_virtual_machine" "jumpbox-windows-vm" {
  count				= var.az_windows_jumpbox.required ? 1 : 0
  name                          = var.az_windows_jumpbox.name
  location                      = var.az_region
  resource_group_name           = var.az_resource_group.name
  network_interface_ids         = [azurerm_network_interface.windows-jumpbox-nic1[0].id]
  vm_size                       = "Standard_D4s_v3"
  delete_os_disk_on_termination = "true"

  storage_os_disk {
    name              = "${var.az_windows_jumpbox.name}-osdisk"
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
    computer_name  = var.az_windows_jumpbox.name
    admin_username = "${var.az_windows_jumpbox.username}"
    admin_password = "${var.az_windows_jumpbox.password}"
  }

  os_profile_windows_config {

  }

  boot_diagnostics {
    enabled = "true"

    storage_uri = var.az_bootdiag_sa.primary_blob_endpoint
  }
}
