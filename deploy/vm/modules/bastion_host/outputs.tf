output "ip" {
  depends_on = ["azurerm_key_vault_certificate"]
  value = "${module.nic_and_pip_setup.fqdn}"
}

output "machine_hostname" {
  depends_on = ["azurerm_key_vault_certificate", "azurerm_virtual_machine.windows_bastion"]

  value = "${local.machine_name}"
}
