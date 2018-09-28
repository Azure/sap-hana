
resource "azurerm_network_security_group" "windows_bastion_nsg" {
  name                = "windows_bastion_nsg"
  location            = "${var.az_region}"
  resource_group_name = "${var.az_resource_group}"

  security_rule {
    name                       = "RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

    security_rule {
    name                       = "winrm"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5986"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags {
    environment = "windows_bastion"
  }
}

module "nic_and_pip_setup" {
  source = "../generic_nic_and_pip"

  az_resource_group         = "${var.az_resource_group}"
  az_region                 = "${var.az_region}"
  name                      = "${local.machine_name}"
  nsg_id                    = "${azurerm_network_security_group.windows_bastion_nsg.id}"
  subnet_id                 = "${var.subnet_id}"
  public_ip_allocation_type = "dynamic"
}

resource "azurerm_virtual_machine" "windows_bastion" {
  name                  = "${local.machine_name}"
  location              = "${var.az_region}"
  resource_group_name   = "${var.az_resource_group}"
  network_interface_ids = ["${module.nic_and_pip_setup.nic_id}"]
  vm_size               = "${var.vm_size}"

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${local.machine_name}"
    admin_username = "${var.bastion_username}"
    admin_password = "${var.pw_bastion}"
  }

  os_profile_secrets {
    source_vault_id = "${azurerm_key_vault.main.id}"
    vault_certificates {
      certificate_url   = "${azurerm_key_vault_certificate.main.secret_id}"
      certificate_store = "My"
    }
  }

  os_profile_windows_config {
    provision_vm_agent = true
    winrm {
      protocol = "Http"
    }
    winrm {
      protocol = "Https"
      certificate_url   = "${azurerm_key_vault_certificate.main.secret_id}"
    }
    # Auto-Login's required to configure WinRM
    additional_unattend_config {
      pass         = "oobeSystem"
      component    = "Microsoft-Windows-Shell-Setup"
      setting_name = "AutoLogon"
      content      = "<AutoLogon><Password><Value>${var.pw_bastion}</Value></Password><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>${var.bastion_username}</Username></AutoLogon>"
    }

    # Unattend config is to enable basic auth in WinRM, required for the provisioner stage.
    additional_unattend_config {
      pass         = "oobeSystem"
      component    = "Microsoft-Windows-Shell-Setup"
      setting_name = "FirstLogonCommands"
      content      = "${file("${path.module}/files/FirstLogonCommands.xml")}"
    }
  }

  tags {
    bastion = ""
  }
}
