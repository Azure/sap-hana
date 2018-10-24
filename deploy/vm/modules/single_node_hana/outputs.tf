output "db_ip" {
  value = "Connect using ${var.vm_user}@${module.create_db.fqdn}"
}

output "windows_bastion_ip" {
  value = "${module.windows_bastion_host.ip}"
}
