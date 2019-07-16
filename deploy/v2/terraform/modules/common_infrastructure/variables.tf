variable "infrastructure" {
  description = "Details of the Azure infrastructure to deploy the SAP landscape into"
}

variable "infra_default" {
  description = "Default argument values for the Azure infrastructure resources"
  default = {
    "region"         = "eastus"
    "resource_group" = "sap-rg"
    "vnets" = {
      "management" = {
        "name"          = "vnet-mgmt"
        "address_space" = "10.0.0.0/16"
        "subnet_default" = {
          "name"   = "subnet-mgmt-default"
          "prefix" = "10.0.1.0/24"
          "nsg" = {
            "name" = "nsg-mgmt-default"
          }

        }
      }
      "sap" = {
        "name"          = "vnet-sap"
        "address_space" = "10.1.0.0/16"
        "subnet_admin" = {
          "name"   = "subnet-sap-admin"
          "prefix" = "10.1.1.0/24"
          "nsg" = {
            "name" = "nsg-sap-admin"
          }

        }
        "subnet_client" = {
          "name"   = "subnet-sap-client"
          "prefix" = "10.1.2.0/24"
          "nsg" = {
            "name" = "nsg-sap-client"
          }

        }
        "subnet_app" = {
          "name"   = "subnet-app"
          "prefix" = "10.1.3.0/24"
          "nsg" = {
            "name" = "nsg-app"
          }

        }
      }
    }
  }
}
