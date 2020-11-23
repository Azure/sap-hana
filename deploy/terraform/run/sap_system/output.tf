output "dns_information_app" {
  value = module.app_tier.dns_info_vms
}

output "dns_information_loadbalancers_app" {
  value = module.app_tier.dns_info_loadbalancers
}
