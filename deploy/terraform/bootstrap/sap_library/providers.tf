/*
Description:

  Constraining provider versions
    =    (or no operator): exact version equality
    !=   version not equal
    >    greater than version number
    >=   greater than or equal to version number
    <    less than version number
    <=   less than or equal to version number
    ~>   pessimistic constraint operator, constraining both the oldest and newest version allowed.
           For example, ~> 0.9   is equivalent to >= 0.9,   < 1.0 
                        ~> 0.8.4 is equivalent to >= 0.8.4, < 0.9
*/

provider "azurerm" {
  version = "~> 2.10"
  features {}
  subscription_id = data.azurerm_key_vault_secret.subscription_id.value
  client_id       = data.azurerm_key_vault_secret.client_id.value
  client_secret   = data.azurerm_key_vault_secret.client_secret.value
  tenant_id       = data.azurerm_key_vault_secret.tenant_id.value
}

provider "azurerm" {
  version = "~> 2.10"
  features {}
  alias = "deployer"
}

terraform {
  required_version = ">= 0.12"
  required_providers {
    external = { version = "~> 1.2" }
    local    = { version = "~> 1.4" }
    random   = { version = "~> 2.2" }
    null     = { version = "~> 2.1" }
  }
}
