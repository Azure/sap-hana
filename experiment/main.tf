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
  sap_instancenum = "00"
}

module "single_node_hana" {
  source = "./modules/single_node_hana"
  sshkey_path_private = "${var.sshkey_path_private}"
  az_resource_group = "${az_resource_group.hana-resource-group.name}"
}
