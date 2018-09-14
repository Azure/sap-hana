# Configure the Microsoft Azure Provider
provider "azurerm" {} #TODO(pabowers): add ability to specify subscription

module "common_setup" {
  source = "../common_setup"

  az_region         = "${var.az_region}"
  az_resource_group = "${var.az_resource_group}"
  sap_instancenum   = "${var.sap_instancenum}"
  sap_sid           = "${var.sap_sid}"
  useHana2          = "${var.useHana2}"
}

module "create_db" {
  source = "../create_db_node"

  az_resource_group         = "${module.common_setup.resource_group_name}"
  az_region                 = "${var.az_region}"
  db_num                    = "${var.db_num}"
  hana_subnet_id            = "${module.common_setup.vnet_subnets[0]}"
  nsg_id                    = "${module.common_setup.nsg_id}"
  public_ip_allocation_type = "${var.public_ip_allocation_type}"
  sap_sid                   = "${var.sap_sid}"
  sshkey_path_public        = "${var.sshkey_path_public}"
  storage_disk_sizes_gb     = "${var.storage_disk_sizes_gb}"
  vm_user                   = "${var.vm_user}"
  vm_size                   = "${var.vm_size}"
}

module "configure_vm" {
  source                = "../playbook-execution"
  ansible_playbook_path = "${var.ansible_playbook_path}"
  az_resource_group     = "${module.common_setup.resource_group_name}"
  sshkey_path_private   = "${var.sshkey_path_private}"
  sap_instancenum       = "${var.sap_instancenum}"
  sap_sid               = "${var.sap_sid}"
  vm_user               = "${var.vm_user}"
  url_sap_sapcar        = "${var.url_sap_sapcar}"
  url_sap_hdbserver     = "${var.url_sap_hdbserver}"
  pw_os_sapadm          = "${var.pw_os_sapadm}"
  pw_os_sidadm          = "${var.pw_os_sidadm}"
  pw_db_system          = "${var.pw_db_system}"
  useHana2              = "${var.useHana2}"
  vms_configured        = "${module.create_db.machine_hostname}"

  url_xsa_runtime     = "${var.url_xsa_runtime}"
  url_di_core         = "${var.url_di_core}"
  url_sapui5          = "${var.url_sapui5}"
  url_portal_services = "${var.url_portal_services}"
  url_xs_services     = "${var.url_xs_services}"
  url_shine_xsa       = "${var.url_shine_xsa}"
  pwd_db_xsaadmin     = "${var.pwd_db_xsaadmin}"
  pwd_db_tenant       = "${var.pwd_db_tenant}"
  pwd_db_shine        = "${var.pwd_db_shine}"
  email_shine         = "${var.email_shine}"
}
