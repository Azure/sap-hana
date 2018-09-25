module "bastion_nsg" {
  source            = "../bastion_nsg"
  az_region         = "${var.az_region}"
  az_resource_group = "${var.az_resource_group}"
  isLinux           = "${var.isLinux}"
}

module "nic_and_pip_setup" {
  source = "../generic_nic_and_pip"

  az_resource_group         = "${var.az_resource_group}"
  az_region                 = "${var.az_region}"
  name                      = "${local.machine_name}"
  nsg_id                    = "${module.bastion_nsg.nsg_id}"
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
  }

  tags {
    bastion = ""
  }
}

# resource "azurerm_virtual_machine_extension" "winrm_extension" {
#   name                 = "winrm_extension"
#   location             = "${var.az_region}"
#   resource_group_name  = "${var.az_resource_group}"
#   virtual_machine_name = "${azurerm_virtual_machine.windows_bastion.name}"
#   publisher            = "Microsoft.Azure.Extensions"
#   type                 = "CustomScript"
#   type_handler_version = "1.4"

#   settings = <<SETTINGS
#     {
#         "fileUris": [
#                 "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vm-winrm-windows/ConfigureWinRM.ps1",
#                 "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vm-winrm-windows/makecert.exe"
#               ],
#         "commandToExecute": "[concat('powershell -ExecutionPolicy Unrestricted -file ConfigureWinRM.ps1 ',variables('hostDNSNameScriptArgument'))]"
#     }
# SETTINGS

#   tags {
#     environment = "winrm_extension"
#   }
# }
