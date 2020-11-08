/*
    Description:
    Importing resources
*/

// Access information about sap vnet
data "azure_virtual_network" "vnet_sap" {
    name = local.vnet_sap_name
    resource_group_name = local.vnet_resource_group_name
}