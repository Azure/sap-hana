/*
Description:

  Output from sap_deployer module.
*/

output "deployer_id" {
  sensitive = true
  value = module.sap_deployer.deployer_id
}

output "vnet_mgmt" {
  sensitive = true
  value = module.sap_deployer.vnet_mgmt
}

output "subnet_mgmt" {
  sensitive = true
  value = module.sap_deployer.subnet_mgmt
}

output "nsg_mgmt" {
  sensitive = true
  value = module.sap_deployer.nsg_mgmt
}

output "deployer_uai" {
  sensitive = true
  value = module.sap_deployer.deployer_uai
}

output "deployer" {
  sensitive = true
  value = module.sap_deployer.deployers
}
