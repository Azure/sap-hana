output "ip" {
  value = "Created vm ${azurerm_virtual_machine.db0.id}"
  value = "Connect using ${var.vm_user}@${local.vmFqdn}"
}