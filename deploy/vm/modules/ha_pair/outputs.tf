output "db0_ip" {
  value = "Connect to db0 using ${var.vm_user}@${module.create_db0.fqdn}"
}

output "db1_ip" {
  value = "Connect to db1 using ${var.vm_user}@${module.create_db1.fqdn}"
}

output "iscsi_ip" {
  value = "Connect to iscsi using ${var.vm_user}@${module.nic_and_pip_setup_iscsi.fqdn}"
}

output "windows_bastion_ip" {
  value = "${module.windows_bastion_host.ip}"
}
