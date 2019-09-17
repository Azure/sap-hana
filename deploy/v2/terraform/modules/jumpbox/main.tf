##################################################################################################################
# JUMPBOXES
##################################################################################################################

# BOOT DIAGNOSTICS ===============================================================================================

# Generates random text for boot diagnostics storage account name
resource "random_id" "random-id" {
  keepers = {
    # Generate a new id only when a new resource group is defined
    resource_group = var.resource-group[0].name
  }
  byte_length = 8
}

# Creates boot diagnostics storage account
resource "azurerm_storage_account" "storageaccount-bootdiagnostics" {
  name                     = lookup(var.infrastructure,"boot_diagnostics_account_name", false) == false ? "diag${random_id.random-id.hex}" : var.infrastructure.boot_diagnostics_account_name
  resource_group_name      = var.resource-group[0].name
  location                 = var.resource-group[0].location
  account_replication_type = "LRS"
  account_tier             = "Standard"
}

# NETWORK SECURITY RULES =========================================================================================

# Creates Windows jumpbox RDP network security rule
resource "azurerm_network_security_rule" "nsr-rdp" {
  count                       = var.infrastructure.vnets.management.subnet_mgmt.nsg.is_existing ? 0 : 1
  name                        = "rdp"
  resource_group_name         = var.nsg-mgmt[0].resource_group_name
  network_security_group_name = var.nsg-mgmt[0].name
  priority                    = 101
  direction                   = "Inbound"
  access                      = "allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = 3389
  source_address_prefix       = "${var.infrastructure.vnets.management.subnet_mgmt.nsg.allowed_ips}"
  destination_address_prefix  = "${var.infrastructure.vnets.management.subnet_mgmt.prefix}"
}

# Creates Linux jumpbox and RTI box SSH network security rule
resource "azurerm_network_security_rule" "nsr-ssh" {
  count                       = var.infrastructure.vnets.management.subnet_mgmt.nsg.is_existing ? 0 : 1
  name                        = "ssh"
  resource_group_name         = var.nsg-mgmt[0].resource_group_name
  network_security_group_name = var.nsg-mgmt[0].name
  priority                    = 102
  direction                   = "Inbound"
  access                      = "allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = 22
  source_address_prefix       = "${var.infrastructure.vnets.management.subnet_mgmt.nsg.allowed_ips}"
  destination_address_prefix  = "${var.infrastructure.vnets.management.subnet_mgmt.prefix}"
}

# NICS ============================================================================================================

# Creates the public IP addresses for Windows VMs
resource "azurerm_public_ip" "public-ip-windows" {
  count               = length(var.jumpboxes.windows)
  name                = "${var.jumpboxes.windows[count.index].name}-public-ip"
  location            = var.resource-group[0].location
  resource_group_name = var.resource-group[0].name
  allocation_method   = "Static"
}

# Creates the NIC and IP address for Windows VMs
resource "azurerm_network_interface" "nic-windows" {
  count                         = length(var.jumpboxes.windows)
  name                          = lookup(var.jumpboxes.windows[count.index], "nic_name", false) != false ? var.jumpboxes.windows[count.index].nic_name : "${var.jumpboxes.windows[count.index].name}-nic1"
  location                      = var.resource-group[0].location
  resource_group_name           = var.resource-group[0].name
  network_security_group_id     = var.nsg-mgmt[0].id

  ip_configuration {
    name                          = "${var.jumpboxes.windows[count.index].name}-nic1-ip"
    subnet_id                     = var.subnet-mgmt[0].id
    private_ip_address            = var.infrastructure.vnets.management.subnet_mgmt.is_existing ? var.jumpboxes.windows[count.index].private_ip_address : lookup(var.jumpboxes.windows[count.index], "private_ip_address", false) != false ? var.jumpboxes.windows[count.index].private_ip_address : cidrhost(var.infrastructure.vnets.management.subnet_mgmt.prefix, (count.index + 4))
    private_ip_address_allocation = "static"
    public_ip_address_id          = azurerm_public_ip.public-ip-windows[count.index].id
  }
}

# Creates the public IP addresses for Linux VMs
resource "azurerm_public_ip" "public-ip-linux" {
  count               = length(var.jumpboxes.linux)
  name                = "${var.jumpboxes.linux[count.index].name}-public-ip"
  location            = var.resource-group[0].location
  resource_group_name = var.resource-group[0].name
  allocation_method   = "Static"
}

# Creates the NIC and IP address for Linux VMs
resource "azurerm_network_interface" "nic-linux" {
  count                         = length(var.jumpboxes.linux)
  name                          = lookup(var.jumpboxes.linux[count.index], "nic_name", false) != false ? var.jumpboxes.linux[count.index].nic_name : "${var.jumpboxes.linux[count.index].name}-nic1"
  location                      = var.resource-group[0].location
  resource_group_name           = var.resource-group[0].name
  network_security_group_id     = var.nsg-mgmt[0].id

  ip_configuration {
    name                          = "${var.jumpboxes.linux[count.index].name}-nic1-ip"
    subnet_id                     = var.subnet-mgmt[0].id
    private_ip_address            = var.infrastructure.vnets.management.subnet_mgmt.is_existing ? var.jumpboxes.linux[count.index].private_ip_address : lookup(var.jumpboxes.linux[count.index], "private_ip_address", false) != false ? var.jumpboxes.linux[count.index].private_ip_address : cidrhost(var.infrastructure.vnets.management.subnet_mgmt.prefix, (count.index + 4 + length(var.jumpboxes.windows)))
    private_ip_address_allocation = "static"
    public_ip_address_id          = azurerm_public_ip.public-ip-linux[count.index].id
  }
}

# VIRTUAL MACHINES ================================================================================================

# Creates Linux VM
resource "azurerm_virtual_machine" "vm-linux" {
  count				= length(var.jumpboxes.linux)
  name                          = var.jumpboxes.linux[count.index].name
  location                      = var.resource-group[0].location
  resource_group_name           = var.resource-group[0].name
  network_interface_ids         = [azurerm_network_interface.nic-linux[count.index].id]
  vm_size                       = var.jumpboxes.linux[count.index].size
  delete_os_disk_on_termination = "true"

  storage_os_disk {
    name              = "${var.jumpboxes.linux[count.index].name}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = var.jumpboxes.linux[count.index].disk_type
  }

  storage_image_reference {
    publisher = var.jumpboxes.linux[count.index].os.publisher
    offer     = var.jumpboxes.linux[count.index].os.offer
    sku       = var.jumpboxes.linux[count.index].os.sku
    version   = "latest"
  }

  os_profile {
    computer_name  = var.jumpboxes.linux[count.index].name
    admin_username = var.jumpboxes.linux[count.index].authentication.username
    admin_password = lookup(var.jumpboxes.linux[count.index].authentication, "password", null)
  }

  os_profile_linux_config {
    disable_password_authentication = var.jumpboxes.linux[count.index].authentication.type != "password" ? true : false
    dynamic "ssh_keys" {
      for_each = var.jumpboxes.linux[count.index].authentication.type != "password" ? ["key"] : []
      content {
        path     = "/home/${var.jumpboxes.linux[count.index].authentication.username}/.ssh/authorized_keys"
        key_data = file(var.jumpboxes.linux[count.index].authentication.path_to_public_key)
      }
    }
  }

  boot_diagnostics {
    enabled     = true
    storage_uri = azurerm_storage_account.storageaccount-bootdiagnostics.primary_blob_endpoint
  }
}

# Creates Windows VM
resource "azurerm_virtual_machine" "vm-windows" {
  count				= length(var.jumpboxes.windows)
  name                          = var.jumpboxes.windows[count.index].name
  location                      = var.resource-group[0].location
  resource_group_name           = var.resource-group[0].name
  network_interface_ids         = [azurerm_network_interface.nic-windows[count.index].id]
  vm_size                       = var.jumpboxes.windows[count.index].size
  delete_os_disk_on_termination = "true"

  storage_os_disk {
    name              = "${var.jumpboxes.windows[count.index].name}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = var.jumpboxes.windows[count.index].disk_type
  }

  storage_image_reference {
    publisher = var.jumpboxes.windows[count.index].os.publisher
    offer     = var.jumpboxes.windows[count.index].os.offer
    sku       = var.jumpboxes.windows[count.index].os.sku
    version   = "latest"
  }

  os_profile {
    computer_name  = var.jumpboxes.windows[count.index].name
    admin_username = var.jumpboxes.windows[count.index].authentication.username
    admin_password = var.jumpboxes.windows[count.index].authentication.password
  }

  os_profile_windows_config {
  }

  boot_diagnostics {
    enabled     = true
    storage_uri = azurerm_storage_account.storageaccount-bootdiagnostics.primary_blob_endpoint
  }
}
