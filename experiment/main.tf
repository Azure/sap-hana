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
module "single_node_hana"