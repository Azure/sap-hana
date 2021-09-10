provider "azurerm" {
  alias = "main"
}

provider "azurerm" {
  alias = "deployer"
}

provider "azuread" {
  alias         = "fencing"
}
