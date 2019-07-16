# Initalizes Azure rm provider
provider "azurerm" {
  version = "~> 1.30.1"
}

# Setup common infrastructure
module "common_infrastructure" {
  source         = "../common_infrastructure"
  infrastructure = var.infrastructure
}
