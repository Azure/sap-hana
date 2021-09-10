/*
  Description:
  Setup infrastructure for sap landscape
*/

// Creates the resource group
resource "azurerm_resource_group" "resource_group" {
  provider = azurerm.main
  count    = local.rg_exists ? 0 : 1
  name     = local.rg_name
  location = local.region

  lifecycle {
    ignore_changes = [
      tags
    ]
  }

}

// Imports data of existing resource group
data "azurerm_resource_group" "resource_group" {
  provider = azurerm.main
  count    = local.rg_exists ? 1 : 0
  name     = local.rg_name
}

// Creates the SAP VNET
resource "azurerm_virtual_network" "vnet_sap" {
  provider            = azurerm.main
  count               = local.vnet_sap_exists ? 0 : 1
  name                = local.vnet_sap_name
  location            = local.rg_exists ? data.azurerm_resource_group.resource_group[0].location : azurerm_resource_group.resource_group[0].location
  resource_group_name = local.rg_exists ? data.azurerm_resource_group.resource_group[0].name : azurerm_resource_group.resource_group[0].name
  address_space       = [local.vnet_sap_addr]
}

// Imports data of existing SAP VNET
data "azurerm_virtual_network" "vnet_sap" {
  provider            = azurerm.main
  count               = local.vnet_sap_exists ? 1 : 0
  name                = split("/", local.vnet_sap_arm_id)[8]
  resource_group_name = split("/", local.vnet_sap_arm_id)[4]
}

# // Peers management VNET to SAP VNET
resource "azurerm_virtual_network_peering" "peering_management_sap" {
  provider                     = azurerm.deployer
  count                        = local.vnet_sap_exists || !var.use_deployer ? 0 : 1
  name                         = substr(format("%s_to_%s", split("/", local.vnet_mgmt_id)[8], local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].name : azurerm_virtual_network.vnet_sap[0].name), 0, 80)
  virtual_network_name         = split("/", local.vnet_mgmt_id)[8]
  resource_group_name          = split("/", local.vnet_mgmt_id)[4]
  remote_virtual_network_id    = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].id : azurerm_virtual_network.vnet_sap[0].id

  allow_virtual_network_access = true
}

// Peers SAP VNET to management VNET
resource "azurerm_virtual_network_peering" "peering_sap_management" {
  provider                     = azurerm.main
  count                        = local.vnet_sap_exists || !var.use_deployer ? 0 : 1
  name                         = substr(format("%s_to_%s", local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].name : azurerm_virtual_network.vnet_sap[0].name, split("/", local.vnet_mgmt_id)[8]), 0, 80)
  resource_group_name          = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  virtual_network_name         = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].name : azurerm_virtual_network.vnet_sap[0].name
  remote_virtual_network_id    = local.vnet_mgmt_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

// Creates boot diagnostics storage account
resource "azurerm_storage_account" "storage_bootdiag" {
  provider                  = azurerm.main
  count                     = length(var.diagnostics_storage_account.arm_id) > 0 ? 0 : 1
  name                      = local.storageaccount_name
  resource_group_name       = local.rg_exists ? data.azurerm_resource_group.resource_group[0].name : azurerm_resource_group.resource_group[0].name
  location                  = local.rg_exists ? data.azurerm_resource_group.resource_group[0].location : azurerm_resource_group.resource_group[0].location
  account_replication_type  = "LRS"
  account_tier              = "Standard"
  enable_https_traffic_only = var.options.enable_secure_transfer == "" ? true : var.options.enable_secure_transfer
}

data "azurerm_storage_account" "storage_bootdiag" {
  provider            = azurerm.main
  count               = length(var.diagnostics_storage_account.arm_id) > 0 ? 1 : 0
  name                = split("/", var.diagnostics_storage_account.arm_id)[8]
  resource_group_name = split("/", var.diagnostics_storage_account.arm_id)[4]
}

//Route table
resource "azurerm_route_table" "rt" {
  provider                      = azurerm.main
  count                         = local.vnet_sap_exists ? 0 : 1
  name                          = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.routetable)
  resource_group_name           = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  location                      = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].location : azurerm_virtual_network.vnet_sap[0].location
  disable_bgp_route_propagation = false
}

resource "azurerm_route" "admin" {
  depends_on = [
    azurerm_route_table.rt
  ]
  provider               = azurerm.main
  count                  = length(local.firewall_ip) > 0 ? 1 : 0
  name                   = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.fw_route)
  resource_group_name    = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  route_table_name       = azurerm_route_table.rt[0].name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.firewall_ip
}



// Creates witness storage account
resource "azurerm_storage_account" "witness_storage" {
  provider                  = azurerm.main
  count                     = length(var.witness_storage_account.arm_id) > 0 ? 0 : 1
  name                      = local.witness_storageaccount_name
  resource_group_name       = local.rg_exists ? data.azurerm_resource_group.resource_group[0].name : azurerm_resource_group.resource_group[0].name
  location                  = local.rg_exists ? data.azurerm_resource_group.resource_group[0].location : azurerm_resource_group.resource_group[0].location
  account_replication_type  = "LRS"
  account_tier              = "Standard"
  enable_https_traffic_only = var.options.enable_secure_transfer == "" ? true : var.options.enable_secure_transfer
}

data "azurerm_storage_account" "witness_storage" {
  provider            = azurerm.main
  count               = length(var.witness_storage_account.arm_id) > 0 ? 1 : 0
  name                = split("/", var.witness_storage_account.arm_id)[8]
  resource_group_name = split("/", var.witness_storage_account.arm_id)[4]
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_sap" {
  provider              = azurerm.deployer
  count                 = length(var.dns_label) > 0 ? 1 : 0
  name                  = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.dns_link)
  resource_group_name   = var.dns_resource_group_name
  private_dns_zone_name = var.dns_label
  virtual_network_id    = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].id : azurerm_virtual_network.vnet_sap[0].id
  registration_enabled  = true
}
