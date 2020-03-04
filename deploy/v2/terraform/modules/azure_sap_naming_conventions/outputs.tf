# Style note: Use shorthand variable names where sensible to keep external usage brief

output "rg" {
  value = module.resource_group_name.result
}

output "lb" {
  value = module.load_balancer_name.result
}

output "lb_fe_ip_conf" {
  value = local.short_name
}

output "lb_be_pool" {
  value = local.short_name
}
