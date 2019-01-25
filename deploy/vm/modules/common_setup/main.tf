# Create a resource group.

resource null_resource "configuration-check" {
  provisioner "local-exec" {
    command = "ansible-playbook ../../ansible/configcheck.yml"
  }
}

resource "azurerm_resource_group" "hana-resource-group" {
  depends_on = ["null_resource.configuration-check"]
  name       = "${var.az_resource_group}"
  location   = "${var.az_region}"

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
