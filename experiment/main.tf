# Create bastion and single HANA node by calling the modules
provider "azurerm" {}

# Create a resource group
resource "azurerm_resource_group" "hana-resource-group" {
  name     = "${var.az_resource_group}"
  location = "${var.az_region}"

  tags {
    environment = "Terraform SAP HANA single node deployment"
  }
}

module "nsg" {
  source = "./modules/nsg_for_hana"
  resource_group_name = "${az_resource_group.hana-resource-group.name}"
  az_region = "${var.az_region}"
  sap_instancenum = "${var.sap_instancenum}"
  sap_sid = "${var.sap_sid}"
}

module "single_node_hana" {
  source = "./modules/single_node_hana"
  sshkey_path_private = "${var.sshkey_path_private}"
  az_resource_group = "${az_resource_group.hana-resource-group.name}"
  az_region = "${var.az_region}"
  sap_instancenum = "${var.sap_instancenum}"
  az_domain_name = "${var.az_domain_name}"
  db_num = "${var.db_num}"
  sap_sid = "${var.sap_sid}"
  vm_user = "${var.vm_user}"
  url_sap_sapcar = "${var.url_sap_sapcar}"
  url_sap_hostagent= "${var.url_sap_hostagent}"
  url_sap_hdbserver = "${var.url_sap_hdbserver}"
  nsg_id = "${module.nsg.nsg-id}"
  pw_os_sapadm = "${var.pw_os_sapadm}"
  pw_os_sidadm = "${var.pw_os_sidadm}"
  pw_db_system = "${var.pw_db_system}"
}
