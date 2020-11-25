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
