# Creates the hana db nic and ip
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


# Creates hana db vm
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
