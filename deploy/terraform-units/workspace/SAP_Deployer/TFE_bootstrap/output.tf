/*
Description:

  Output from sap_deployer module.
*/

output "deployer-id" {
  value = module.sap_deployer.deployer-id
}

output "vnet-mgmt" {
  value = module.sap_deployer.vnet-mgmt
}

output "deployer-uai" {
  value = module.sap_deployer.deployer-uai
}
