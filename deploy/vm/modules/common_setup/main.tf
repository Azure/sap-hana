# Create a resource group.
resource "azurerm_resource_group" "hana-resource-group" {
  name     = "${var.az_resource_group}"
  location = "${var.az_region}"

  tags {
    environment = "Terraform SAP HANA deployment"
  }
}

module "vnet" {
  source  = "Azure/vnet/azurerm"
  version = "1.2.0"

  address_space       = "10.0.0.0/21"
  location            = "${var.az_region}"
  resource_group_name = "${var.az_resource_group}"
  subnet_names        = ["hdb-subnet"]
  subnet_prefixes     = ["10.0.0.0/24"]
  vnet_name           = "${var.sap_sid}-vnet"

  tags {
    environment = "Terraform HANA vnet and subnet creation"
  }
}

# This module creates a network security group with the ports opened that are needed for HANA.
module "nsg" {
  source              = "../nsg_for_hana"
  resource_group_name = "${azurerm_resource_group.hana-resource-group.name}"
  az_region           = "${var.az_region}"
  sap_instancenum     = "${var.sap_instancenum}"
  sap_sid             = "${var.sap_sid}"
  useHana2            = "${var.useHana2}"
  use_existing_nsg    = "${var.use_existing_nsg == local.empty_string}"
}
