# Configure the Microsoft Azure Provider
provider "azurerm" {}

module "common_setup" {
  source            = "../common_setup"
  az_region         = "${var.az_region}"
  az_resource_group = "${var.az_resource_group}"
  sap_instancenum   = "${var.sap_instancenum}"
  sap_sid           = "${var.sap_sid}"
  use_existing_nsg  = "${var.defined_nsg}"
  useHana2          = "${var.useHana2}"
}

module "create_db" {
  source = "../create_db_node"

  az_resource_group         = "${module.common_setup.resource_group_name}"
  az_region                 = "${var.az_region}"
  db_num                    = "${var.db_num}"
  hana_subnet_id            = "${module.common_setup.vnet_subnets[0]}"
  nsg_id                    = "${module.common_setup.nsg_id}"
  private_ip_address        = "${var.private_ip_address_hdb}"
  public_ip_allocation_type = "${var.public_ip_allocation_type}"
  sap_sid                   = "${var.sap_sid}"
  sshkey_path_public        = "${var.sshkey_path_public}"
  storage_disk_sizes_gb     = "${var.storage_disk_sizes_gb}"
  vm_user                   = "${var.vm_user}"
  vm_size                   = "${var.vm_size}"
}

module "windows_bastion_host" {
  source             = "../windows_bastion_host"
  az_resource_group  = "${module.common_setup.resource_group_name}"
  az_region          = "${var.az_region}"
  sap_sid            = "${var.sap_sid}"
  subnet_id          = "${module.common_setup.vnet_subnets[0]}"
  bastion_username   = "${var.bastion_username_windows}"
  private_ip_address = "${var.private_ip_address_windows_bastion}"
  pw_bastion         = "${var.pw_bastion_windows}"
  windows_bastion    = "${var.windows_bastion}"
}

module "configure_vm" {
  source                     = "../playbook-execution"
  ansible_playbook_path      = "${var.ansible_playbook_path}"
  az_resource_group          = "${module.common_setup.resource_group_name}"
  db_num                     = "${var.db_num}"
  sshkey_path_private        = "${var.sshkey_path_private}"
  sap_instancenum            = "${var.sap_instancenum}"
  sap_sid                    = "${var.sap_sid}"
  vm_user                    = "${var.vm_user}"
  url_sap_sapcar             = "${var.url_sap_sapcar}"
  url_sap_hdbserver          = "${var.url_sap_hdbserver}"
  pw_os_sapadm               = "${var.pw_os_sapadm}"
  pw_os_sidadm               = "${var.pw_os_sidadm}"
  pw_db_system               = "${var.pw_db_system}"
  useHana2                   = "${var.useHana2}"
  vms_configured             = "${module.create_db.machine_hostname}, ${module.windows_bastion_host.machine_hostname}"
  url_xsa_runtime            = "${var.url_xsa_runtime}"
  url_di_core                = "${var.url_di_core}"
  url_sapui5                 = "${var.url_sapui5}"
  url_portal_services        = "${var.url_portal_services}"
  url_xs_services            = "${var.url_xs_services}"
  url_shine_xsa              = "${var.url_shine_xsa}"
  pwd_db_xsaadmin            = "${var.pwd_db_xsaadmin}"
  pwd_db_tenant              = "${var.pwd_db_tenant}"
  pwd_db_shine               = "${var.pwd_db_shine}"
  email_shine                = "${var.email_shine}"
  install_xsa                = "${var.install_xsa}"
  install_shine              = "${var.install_shine}"
  install_cockpit            = "${var.install_cockpit}"
  url_cockpit                = "${var.url_cockpit}"
  url_sapcar_windows         = "${var.url_sapcar_windows}"
  url_hana_studio_windows    = "${var.url_hana_studio_windows}"
  azure_service_principal_id = "${var.azure_service_principal_id}"
  azure_service_principal_pw = "${var.azure_service_principal_pw}"
  bastion_username_windows   = "${var.bastion_username_windows}"
  pw_bastion_windows         = "${var.pw_bastion_windows}"
}
