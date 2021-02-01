output "dns_information_anydb" {
  value = module.anydb_node.dns_info_vms
}

output "dns_information_loadbalancers_anydb" {
  value = module.anydb_node.dns_info_loadbalancers
}

output "dns_information_hanadb" {
  value = module.hdb_node.dns_info_vms
}

output "dns_information_loadbalancers_hanadb" {
  value = module.hdb_node.dns_info_loadbalancers
}

output "dns_information_app" {
  value = module.app_tier.dns_info_vms
}

output "dns_information_loadbalancers_app" {
  value = module.app_tier.dns_info_loadbalancers
}
output "app_vm_ids" {
  value = module.app_tier.app_vm_ids
}

output "scs_vm_ids" {
  value = module.app_tier.scs_vm_ids
}

output "web_vm_ids" {
  value = module.app_tier.web_vm_ids
}

output "hanadb_vm_ids" {
  value = module.hdb_node.hanadb_vm_ids
}

output "anydb_vm_ids" {
  value = module.anydb_node.anydb_vm_ids
}

output "temp" {
  value = data.terraform_remote_state.landscape.outputs
}