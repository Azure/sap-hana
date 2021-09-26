/*
Description:

  Define infrastructure resources for deployer(s).
*/

// TODO: Example Documentation block follows:


/*--------------------------------------+---------------------------------------*
*                                                                               *
*                                RESOURCE GROUPS                                *
*                                                                               *
*---------------------------------------4---------------------------------------8
Function:
  Creates a Resorce Group.

Description:
  Resorce Group in which to group all the Resources that are deployed for the
  Deployer in this unit of execution.

Usage:

  local.enable_deployers
      Variable                  : local.enable_deployers [true|false] derived from local.deployer_input based on legnth greater than zero
      Variable                  : local.deployer_input is a copy of var.defaults
      Variable                  : var.defaults defined empty
      Module Caller             : Pass var.deployers object into module
      Input                     : Any overrides are inserted (JSON or TFVARS)
      Main                      : Defines empty var.deployers object [{}]


  local.rg_name
      Variable                  : local.rg_name derived from default format("%s%s", local.prefix, local.resource_suffixes.deployer_rg) or overridden with var.infrastructure.resource_group.name
        Override)
          Variable              : var.infrastructure.resource_group.name is contained in var.infrastructure.resource_group
          Variable              : var.infrastructure.resource_group is contained in var.infrastructure
          Variable              : var.infrastructure defined empty
          Module Caller         : Pass var.infrastructure object into module as infrastructure
          Input                 : Any overrides are inserted (JSON or TFVARS)
          Main                  : Defines empty var.infrastructure object {}

        Default)
          1)  Variable          : local.prefix derived from var.infrastructure.resource_group.name if present in JSON, otherwise default to var.naming.prefix.DEPLOYER
              Override)
                Variable        : var.infrastructure.resource_group.name is contained in var.infrastructure.resource_group
                Variable        : var.infrastructure.resource_group is contained in var.infrastructure
                Variable        : var.infrastructure defined empty
                Module Caller   : Pass var.infrastructure object into module
                Input           : Any overrides are inserted (JSON or TFVARS)
                Main            : Defines empty var.infrastructure object {}
            
              Default)
                Variable        : var.naming.prefix.DEPLOYER is contained in var.naming.prefix
                Variable        : var.naming.prefix is contained in var.naming
                Variable        : var.naming defined empty
                Module Caller   : Pass module.sap_namegenerator.naming object into module as naming

          2)  Variable          : local.resource_suffixes.deployer_rg is an object contained in local.resource_suffixes
              Variable          : local.resource_suffixes is a copy of var.naming.resource_suffixes
              Variable          : var.naming.resource_suffixes is contained in var.naming
              Variable          : var.naming defined empty
              Module Caller     : Pass module.sap_namegenerator.naming object into module as naming


  local.region
      Variable                  : local.region derived from var.infrastructure.region
      Variable                  : var.infrastructure.region is contained in var.infrastructure
      Variable                  : var.infrastructure defined empty
      Module Caller             : Pass var.infrastructure object into module as infrastructure
      Input                     : Required INPUT parameter (JSON or TFVARS)
      Main                      : Defines empty var.infrastructure object {}
*/

resource "azurerm_resource_group" "deployer" {
  count    = local.enable_deployers && !local.rg_exists ? 1 : 0
  name     = local.rg_name
  location = local.region
  tags     = var.infrastructure.tags

}

data "azurerm_resource_group" "deployer" {
  count = local.enable_deployers && local.rg_exists ? 1 : 0
  name  = local.rg_name
}
// TODO: Add management lock when this issue is addressed https://github.com/terraform-providers/terraform-provider-azurerm/issues/5473
//        Management lock should be implemented id a seperate Terraform workspace


// Create/Import management vnet
resource "azurerm_virtual_network" "vnet_mgmt" {
  count               = (local.enable_deployers && !local.vnet_mgmt_exists) ? 1 : 0
  name                = local.vnet_mgmt_name
  resource_group_name = local.rg_exists ? data.azurerm_resource_group.deployer[0].name : azurerm_resource_group.deployer[0].name
  location            = local.rg_exists ? data.azurerm_resource_group.deployer[0].location : azurerm_resource_group.deployer[0].location
  address_space       = [local.vnet_mgmt_addr]
}

data "azurerm_virtual_network" "vnet_mgmt" {
  count               = (local.enable_deployers && local.vnet_mgmt_exists) ? 1 : 0
  name                = split("/", local.vnet_mgmt_arm_id)[8]
  resource_group_name = split("/", local.vnet_mgmt_arm_id)[4]
}

// Create/Import management subnet
resource "azurerm_subnet" "subnet_mgmt" {
  count                = (local.enable_deployers && !local.sub_mgmt_exists) ? 1 : 0
  name                 = local.sub_mgmt_name
  resource_group_name  = local.vnet_mgmt_exists ? data.azurerm_virtual_network.vnet_mgmt[0].resource_group_name : azurerm_virtual_network.vnet_mgmt[0].resource_group_name
  virtual_network_name = local.vnet_mgmt_exists ? data.azurerm_virtual_network.vnet_mgmt[0].name : azurerm_virtual_network.vnet_mgmt[0].name
  address_prefixes     = [local.sub_mgmt_prefix]

  enforce_private_link_endpoint_network_policies = true
  enforce_private_link_service_network_policies  = false

  service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
}

data "azurerm_subnet" "subnet_mgmt" {
  count                = (local.enable_deployers && local.sub_mgmt_exists) ? 1 : 0
  name                 = split("/", local.sub_mgmt_arm_id)[10]
  resource_group_name  = split("/", local.sub_mgmt_arm_id)[4]
  virtual_network_name = split("/", local.sub_mgmt_arm_id)[8]
}

// Creates boot diagnostics storage account for Deployer
resource "azurerm_storage_account" "deployer" {
  count                     = local.enable_deployers ? 1 : 0
  name                      = local.storageaccount_names
  resource_group_name       = local.rg_exists ? data.azurerm_resource_group.deployer[0].name : azurerm_resource_group.deployer[0].name
  location                  = local.rg_exists ? data.azurerm_resource_group.deployer[0].location : azurerm_resource_group.deployer[0].location
  account_replication_type  = "LRS"
  account_tier              = "Standard"
  enable_https_traffic_only = local.enable_secure_transfer
}
