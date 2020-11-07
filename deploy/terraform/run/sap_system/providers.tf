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
  client_id       = local.spn.client_id
  client_secret   = local.spn.client_secret
  tenant_id       = local.spn.tenant_id
}

provider "azurerm" {
  features {}
  alias = "deployer"
}

provider "azuread" {
  client_id     = local.spn.client_id
  client_secret = local.spn.client_secret
  tenant_id     = local.spn.tenant_id
}

terraform {
  required_version = ">= 0.13"
  required_providers {
    external = {
      source  = "hashicorp/external"
      version = "~> 1.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 1.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 2.2"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 2.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 2.2"
    }
    azuread = {
      source = "hashicorp/azuread"
      version = ">= 0.10.0"
    }
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 2.35.0"
    }
  }
}
