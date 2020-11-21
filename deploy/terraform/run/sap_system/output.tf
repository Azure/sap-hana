output "dns_information" {
    value = module.app_tier.dns_info_vms
}

output "dns_information_loadbalancers" {
    value = module.app_tier.dns_info_loadbalancers
}