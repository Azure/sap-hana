/*
Description:

  Output from sap_deployer module.
*/

output "deployer_id" {
  value = module.sap_deployer.deployer_id
}

output "vnet_mgmt" {
  value = module.sap_deployer.vnet_mgmt
}

output "subnet_mgmt" {
  value = module.sap_deployer.subnet_mgmt
}

output "nsg_mgmt" {
  value = module.sap_deployer.nsg_mgmt
}

output "deployer_uai" {
  value = module.sap_deployer.deployer_uai
}

output "deployer" {
  value = module.sap_deployer.deployers
}
