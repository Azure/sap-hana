##################################################################################################################
# JUMPBOXES
##################################################################################################################

# BOOT DIAGNOSTICS ===============================================================================================

# Generates random text for boot diagnostics storage account name
resource "random_id" "random-id" {
  keepers = {
    # Generate a new id only when a new resource group is defined
    resource_group = var.rg[0].name
  }
  byte_length = 8
}

# Creates boot diagnostics storage account
resource "azurerm_storage_account" "storageaccount-bootdiagnostics" {
  name                     = "diag${random_id.random-id.hex}"
  resource_group_name      = var.rg[0].name
  location                 = var.rg[0].location
  account_replication_type = "LRS"
  account_tier             = "Standard"
}

# NETWORK SECURITY RULES =========================================================================================

# Creates Windows jumpbox RDP network security rule
resource "azurerm_network_security_rule" "nsr-rdp" {
  count                       = lookup(var.jumpboxes, "windows_jumpbox", false) != false ? 1 : 0
  name                        = "rdp"
  resource_group_name         = var.rg[0].name
  network_security_group_name = var.nsg-mgmt[0].name
  priority                    = 101
  direction                   = "Inbound"
  access                      = "allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = 3389
  source_address_prefix       = "*"
  destination_address_prefix  = lookup(var.jumpboxes.windows_jumpbox, "private_ip_address", false) != false ? var.jumpboxes.windows_jumpbox.private_ip_address : cidrhost(var.infrastructure.vnets.management.subnet_mgmt.prefix, 5)
}

# Creates Linux jumpbox and RTI box SSH network security rule
resource "azurerm_network_security_rule" "nsr-ssh" {
  for_each                    = { for k, v in var.jumpboxes : (k) => (v) if replace(v.os.publisher, "Windows", "") == v.os.publisher }
  name                        = "${each.key}-ssh"
  resource_group_name         = var.rg[0].name
  network_security_group_name = var.nsg-mgmt[0].name
  priority                    = each.key == "linux_jumpbox" ? 102 : 103
  direction                   = "Inbound"
  access                      = "allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = 22
  source_address_prefix       = "*"
  destination_address_prefix  = each.key == "linux_jumpbox" ? lookup(var.jumpboxes.linux_jumpbox, "private_ip_address", false) != false ? each.value.private_ip_address : cidrhost(var.infrastructure.vnets.management.subnet_mgmt.prefix, 4) : each.key == "rti_box" ? lookup(var.jumpboxes.rti_box, "private_ip_address", false) != false ? each.value.private_ip_address : cidrhost(var.infrastructure.vnets.management.subnet_mgmt.prefix, 6) : null
}

# NICS ============================================================================================================

# Creates the public IP addresses
resource "azurerm_public_ip" "public-ip" {
  for_each            = { for k, v in var.jumpboxes : (k) => (v)}
  name                = "${each.key}-public-ip"
  location            = var.rg[0].location
  resource_group_name = var.rg[0].name
  allocation_method   = "Static"
}

# Creates the jumpbox NIC and IP address
resource "azurerm_network_interface" "nic-primary" {
  for_each                      = var.jumpboxes
  name                          = "${each.value.name}-nic1"
  location                      = var.rg[0].location
  resource_group_name           = var.rg[0].name
  network_security_group_id     = var.nsg-mgmt[0].id
  enable_accelerated_networking = "true"

  ip_configuration {
    name                          = "${each.value.name}-nic1-ip"
    subnet_id                     = var.subnet-mgmt[0].id
    private_ip_address            = var.infrastructure.vnets.management.subnet_mgmt.is_existing ? each.value.private_ip_address : each.key == "linux_jumpbox" ? lookup(var.jumpboxes.linux_jumpbox, "private_ip_address", false) != false ? each.value.private_ip_address : cidrhost(var.infrastructure.vnets.management.subnet_mgmt.prefix, 4) : each.key == "windows_jumpbox" ? lookup(var.jumpboxes.windows_jumpbox, "private_ip_address", false) != false ? each.value.private_ip_address : cidrhost(var.infrastructure.vnets.management.subnet_mgmt.prefix, 5) : each.key == "rti_box" ? lookup(var.jumpboxes.rti_box, "private_ip_address", false) != false ? each.value.private_ip_address : cidrhost(var.infrastructure.vnets.management.subnet_mgmt.prefix, 6) : null
    private_ip_address_allocation = "static"
    public_ip_address_id          = azurerm_public_ip.public-ip[each.key].id
  }
}

# VIRTUAL MACHINES ================================================================================================

# Creates Linux VM
resource "azurerm_virtual_machine" "vm-linux" {
  for_each                      = { for k, v in var.jumpboxes : (k) => (v) if replace(v.os.publisher, "Windows", "") == v.os.publisher }
  name                          = each.value.name
  location                      = var.rg[0].location
  resource_group_name           = var.rg[0].name
  network_interface_ids         = [azurerm_network_interface.nic-primary[each.key].id]
  vm_size                       = "Standard_D4s_v3"
  delete_os_disk_on_termination = "true"

  storage_os_disk {
    name              = "${each.value.name}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
  }

  storage_image_reference {
    publisher = each.value.os.publisher
    offer     = each.value.os.offer
    sku       = each.value.os.sku
    version   = "latest"
  }

  os_profile {
    computer_name  = each.value.name
    admin_username = each.value.authentication.username
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/${each.value.authentication.username}/.ssh/authorized_keys"
      key_data = file(each.value.authentication.path_to_public_key)
    }
  }

  boot_diagnostics {
    enabled     = true
    storage_uri = azurerm_storage_account.storageaccount-bootdiagnostics.primary_blob_endpoint
  }
}

# Creates Windows VM
resource "azurerm_virtual_machine" "vm-windows" {
  for_each                      = { for k, v in var.jumpboxes : (k) => (v) if replace(v.os.publisher, "Windows", "") != v.os.publisher }
  name                          = each.value.name
  location                      = var.rg[0].location
  resource_group_name           = var.rg[0].name
  network_interface_ids         = [azurerm_network_interface.nic-primary[each.key].id]
  vm_size                       = "Standard_D4s_v3"
  delete_os_disk_on_termination = "true"

  storage_os_disk {
    name              = "${each.value.name}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
  }

  storage_image_reference {
    publisher = each.value.os.publisher
    offer     = each.value.os.offer
    sku       = each.value.os.sku
    version   = "latest"
  }

  os_profile {
    computer_name  = each.value.name
    admin_username = each.value.authentication.username
    admin_password = each.value.authentication.password
  }

  os_profile_windows_config {
  }

  boot_diagnostics {
    enabled     = true
    storage_uri = azurerm_storage_account.storageaccount-bootdiagnostics.primary_blob_endpoint
  }
}
