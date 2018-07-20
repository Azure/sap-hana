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

module "vnet" {
  source  = "Azure/vnet/azurerm"
  version = "1.0.0"

  address_space       = "10.0.0.0/21"
  location            = "${var.az_region}"
  resource_group_name = "${var.az_resource_group}"
  subnet_names        = ["hdb-subnet"]
  subnet_prefixes     = ["10.0.1.0/24"]
  vnet_name           = "${var.sap_sid}-vnet"

  tags {
    environment = "Terraform HANA vnet and subnet creation"
  }
}

module "nsg" {
  source              = "./modules/nsg_for_hana"
  resource_group_name = "${azurerm_resource_group.hana-resource-group.name}"
  az_region           = "${var.az_region}"
  sap_instancenum     = "${var.sap_instancenum}"
  sap_sid             = "${var.sap_sid}"
}

# TODO: see if can do this in a better way than in this file
resource "azurerm_subnet" "subnet" {
  depends_on                = ["module.vnet"]
  name                      = "hdb-subnet"
  address_prefix            = "10.0.1.0/24"
  resource_group_name       = "${var.az_resource_group}"
  virtual_network_name      = "${var.sap_sid}-vnet"
  network_security_group_id = "${module.nsg.nsg-id}"
}

module "single_node_hana" {
  source = "./modules/single_node_hana"

  sshkey_path_private = "${var.sshkey_path_private}"
  sshkey_path_public  = "${var.sshkey_path_public}"
  az_resource_group   = "${azurerm_resource_group.hana-resource-group.name}"
  az_region           = "${var.az_region}"
  sap_instancenum     = "${var.sap_instancenum}"
  az_domain_name      = "${var.az_domain_name}"
  db_num              = "${var.db_num}"
  sap_sid             = "${var.sap_sid}"
  vm_user             = "${var.vm_user}"
  url_sap_sapcar      = "${var.url_sap_sapcar}"
  url_sap_hostagent   = "${var.url_sap_hostagent}"
  url_sap_hdbserver   = "${var.url_sap_hdbserver}"
  nsg_id              = "${module.nsg.nsg-id}"
  pw_os_sapadm        = "${var.pw_os_sapadm}"
  pw_os_sidadm        = "${var.pw_os_sidadm}"
  pw_db_system        = "${var.pw_db_system}"
  hana_subnet_id      = "${module.vnet.vnet_subnets[0]}"
}
