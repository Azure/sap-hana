# Configure the Microsoft Azure Provider
provider "azurerm" {} #TODO(pabowers): add ability to specify subscription

# Create a resource group
resource "azurerm_resource_group" "hana-resource-group" {
  name     = "${var.az_resource_group}"
  location = "${var.az_region}"

  tags {
    environment = "Terraform SAP HANA single node deployment"
  }
}

# TODO(pabowers): switch to use the Terraform registry version when release for nsg support becomes available
module "vnet" {
  source = "github.com/Azure/terraform-azurerm-vnet"

  address_space       = "10.0.0.0/21"
  location            = "${var.az_region}"
  resource_group_name = "${var.az_resource_group}"
  subnet_names        = ["hdb-subnet"]
  subnet_prefixes     = ["10.0.0.0/24"]
  vnet_name           = "${var.sap_sid}-vnet"

  nsg_ids = {
    "hdb-subnet" = "${module.nsg.nsg-id}"
  }

  tags {
    environment = "Terraform HANA vnet and subnet creation"
  }
}

module "nsg" {
  source              = "../nsg_for_hana"
  resource_group_name = "${azurerm_resource_group.hana-resource-group.name}"
  az_region           = "${var.az_region}"
  sap_instancenum     = "${var.sap_instancenum}"
  sap_sid             = "${var.sap_sid}"
  useHana2            = "${var.useHana2}"
}

module "create_db" {
  source = "../create_db_node"

  az_resource_group     = "${azurerm_resource_group.hana-resource-group.name}"
  az_region             = "${var.az_region}"
  db_num                = "${var.db_num}"
  hana_subnet_id        = "${module.vnet.vnet_subnets[0]}"
  nsg_id                = "${module.nsg.nsg-id}"
  sap_sid               = "${var.sap_sid}"
  sshkey_path_public    = "${var.sshkey_path_public}"
  storage_disk_sizes_gb = "${var.storage_disk_sizes_gb}"
  vm_user               = "${var.vm_user}"
  vm_size               = "${var.vm_size}"
}

module "configure_vm" {
  source = "../playbook-execution"

  az_resource_group   = "${azurerm_resource_group.hana-resource-group.name}"
  sshkey_path_private = "${var.sshkey_path_private}"
  sap_instancenum     = "${var.sap_instancenum}"
  sap_sid             = "${var.sap_sid}"
  vm_user             = "${var.vm_user}"
  url_sap_sapcar      = "${var.url_sap_sapcar}"
  url_sap_hdbserver   = "${var.url_sap_hdbserver}"
  pw_os_sapadm        = "${var.pw_os_sapadm}"
  pw_os_sidadm        = "${var.pw_os_sidadm}"
  pw_db_system        = "${var.pw_db_system}"
  useHana2            = "${var.useHana2}"
  vms_configured      = "${module.create_db.machine_hostname}"
}
