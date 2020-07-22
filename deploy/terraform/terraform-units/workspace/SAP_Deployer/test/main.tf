provider "azurerm" {
  features {}
}

data "terraform_remote_state" "tfstate" {
  backend = "local"

  config = {
    path = "${path.module}/file/terraform.tfstate"
  }
}

data azurerm_resource_group rg {
  name = data.terraform_remote_state.tfstate.outputs.rg.name
}

resource "azurerm_virtual_network" "vnet-test" {
  name                = "vnet-test"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  address_space       = ["10.7.0.0/16"]
}

