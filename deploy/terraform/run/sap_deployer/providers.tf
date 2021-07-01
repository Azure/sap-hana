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
}

terraform {
  required_version = ">= 0.14"
  required_providers {
    external = {
      source  = "hashicorp/external"
    }
    local = {
      source  = "hashicorp/local"
    }
    random = {
      source  = "hashicorp/random"
    }
    null = {
      source  = "hashicorp/null"
    }
    tls = {
      source  = "hashicorp/tls"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
    }
  }
}
