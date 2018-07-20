output "ip" {
  value = "Created vm ${azurerm_virtual_machine.db.id}"
  value = "Connect using ${var.vm_user}@${local.vm_fqdn}"
}
