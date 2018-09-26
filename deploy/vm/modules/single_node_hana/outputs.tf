output "ip" {
  value = "Connect using ${var.vm_user}@${module.create_db.fqdn}"
}
