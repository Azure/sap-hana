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
  features {}
  subscription_id = local.spn.subscription_id
  client_id       = local.use_spn ? local.spn.client_id : null
  client_secret   = local.use_spn ? local.spn.client_secret : null
  tenant_id       = local.use_spn ? local.spn.tenant_id : null
  use_msi         = false
  alias           = "main"
}

provider "azurerm" {
  features {}
  subscription_id = length(local.deployer_subscription_id) > 0 ? local.deployer_subscription_id : null
  alias           = "deployer"
}

provider "azuread" {
  client_id     = local.use_spn ? local.spn.client_id : null
  client_secret = local.use_spn ? local.spn.client_secret : null
  tenant_id     = local.spn.tenant_id
}


terraform {
  required_version = ">= 0.14"
  required_providers {
    external = {
      source = "hashicorp/external"
    }
    local = {
      source = "hashicorp/local"
    }
    random = {
      source = "hashicorp/random"
    }
    null = {
      source = "hashicorp/null"
    }
    azuread = {
      source = "hashicorp/azuread"
    }
    azurerm = {
      source = "hashicorp/azurerm"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
}
