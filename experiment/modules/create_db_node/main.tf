module "nic_and_pip_setup" {
  source = "../generic_nic_and_pip"

  az_resource_group         = "${var.az_resource_group}"
  az_region                 = "${var.az_region}"
  name                      = "${var.sap_sid}-db${var.db_num}"
  nsg_id                    = "${var.nsg_id}"
  subnet_id                 = "${var.hana_subnet_id}"
  private_ip_address        = "${var.private_ip_address}"
  public_ip_allocation_type = "${var.public_ip_allocation_type}"
  backend_ip_pool_ids       = "${var.backend_ip_pool_ids}"
}

module "vm_and_disk_creation" {
  source = "../generic_vm_and_disk_creation"

  sshkey_path_public    = "${var.sshkey_path_public}"
  az_resource_group     = "${var.az_resource_group}"
  az_region             = "${var.az_region}"
  storage_disk_sizes_gb = "${var.storage_disk_sizes_gb}"
  machine_name          = "${lower(var.sap_sid)}-db${var.db_num}"
  vm_user               = "${var.vm_user}"
  vm_size               = "${var.vm_size}"
  nic_id                = "${module.nic_and_pip_setup.nic_id}"
  availability_set_id   = "${var.availability_set_id}"
  machine_type          = "database-${var.az_resource_group}"
  tags                  = "${map(local.vm_db_name, "")}"
}
