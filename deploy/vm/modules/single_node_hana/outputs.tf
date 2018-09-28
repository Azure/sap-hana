output "db_ip" {
  value = "Connect using ${var.vm_user}@${module.create_db.fqdn}"
}

output "bastion_ip" {
  value = "${module.bastion_host.ip}"
}