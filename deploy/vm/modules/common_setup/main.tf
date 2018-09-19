# Create a resource group
resource "azurerm_resource_group" "hana-resource-group" {
  name     = "${var.az_resource_group}"
  location = "${var.az_region}"

  tags {
    environment = "Terraform SAP HANA HA-pair deployment"
  }
}

# TODO(pabowers): switch to use the Terraform registry version when release for nsg support becomes available
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

module "nsg" {
  source              = "../nsg_for_hana"
  resource_group_name = "${azurerm_resource_group.hana-resource-group.name}"
  az_region           = "${var.az_region}"
  sap_instancenum     = "${var.sap_instancenum}"
  sap_sid             = "${var.sap_sid}"
  useHana2            = "${var.useHana2}"
}
