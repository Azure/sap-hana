output "hdb0_ip" {
  value = "${module.create_hdb0.fqdn}"
}

output "hdb1_ip" {
  value = "${module.create_hdb1.fqdn}"
}

output "hdb_vm_user" {
  value = "${var.vm_user}"
}

output "windows_bastion_ip" {
  value = "${module.windows_bastion_host.ip}"
}

output "windows_bastion_user" {
  value = "${var.bastion_username_windows}"
}
