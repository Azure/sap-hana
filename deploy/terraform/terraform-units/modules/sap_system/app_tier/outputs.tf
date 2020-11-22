output "nics_scs" {
  value = azurerm_network_interface.scs
}

output "nics_app" {
  value = azurerm_network_interface.app
}

output "nics_web" {
  value = azurerm_network_interface.web
}

output "nics_scs_admin" {
  value = azurerm_network_interface.scs_admin
}

output "nics_app_admin" {
  value = azurerm_network_interface.app_admin
}

output "nics_web_admin" {
  value = azurerm_network_interface.web_admin
}

output "app_ip" {
  value = azurerm_network_interface.app[*].private_ip_address
}

output "app_admin_ip" {
  value = azurerm_network_interface.app_admin[*].private_ip_address
}

output "scs_ip" {
  value = azurerm_network_interface.scs[*].private_ip_address
}

output "scs_admin_ip" {
  value = azurerm_network_interface.scs_admin[*].private_ip_address
}

output "web_ip" {
  value = azurerm_network_interface.web[*].private_ip_address
}

output "web_admin_ip" {
  value = azurerm_network_interface.web_admin[*].private_ip_address
}

output "web_lb_ip" {
  value = local.enable_deployment && local.webdispatcher_count > 0 ? azurerm_lb.web[0].frontend_ip_configuration[0].private_ip_address : ""
}

output "scs_lb_ip" {
  value = local.enable_deployment ? azurerm_lb.scs[0].frontend_ip_configuration[0].private_ip_address : ""
}

output "ers_lb_ip" {
  value = local.enable_deployment ? azurerm_lb.scs[0].frontend_ip_configuration[1].private_ip_address : ""
}

output "application" {
  value = local.application
}

// Output for DNS

output "dns_info_vms" {
  value = concat(
    flatten([for idx, vm in local.app_virtualmachine_names :
      {
        // If dual NICs are used the admin nic is the first
        format("%s%s%s%s", local.prefix, var.naming.separator, vm, local.resource_suffixes.vm) = local.apptier_dual_nics ? (
          azurerm_network_interface.app_admin[idx].private_ip_address) : (
          azurerm_network_interface.app[idx].private_ip_address
        )
      }
    ]), ! local.apptier_dual_nics ? [{}] :
    flatten([for idx, vm in var.naming.virtualmachine_names.APP_SECONDARY_DNSNAME :
      {
        var.naming.virtualmachine_names.APP_SECONDARY_DNSNAME[idx] = azurerm_network_interface.app[idx].private_ip_address
      }
    ]),
    flatten([for idx, vm in local.scs_virtualmachine_names :
      {
        format("%s%s%s%s", local.prefix, var.naming.separator, vm, local.resource_suffixes.vm) = local.apptier_dual_nics ? (
          azurerm_network_interface.scs_admin[idx].private_ip_address) : (
          azurerm_network_interface.scs[idx].private_ip_address
        )

      }
    ]), ! local.apptier_dual_nics ? [{}] :
    flatten([for idx, vm in var.naming.virtualmachine_names.SCS_SECONDARY_DNSNAME :
      {
        var.naming.virtualmachine_names.SCS_SECONDARY_DNSNAME[idx] = azurerm_network_interface.scs[idx].private_ip_address
      }
    ]),
    flatten([for idx, vm in local.web_virtualmachine_names :
      {
        format("%s%s%s%s", local.prefix, var.naming.separator, vm, local.resource_suffixes.vm) = local.apptier_dual_nics ? (
          azurerm_network_interface.web_admin[idx].private_ip_address) : (
          azurerm_network_interface.web[idx].private_ip_address
        )
      }
    ]), ! local.apptier_dual_nics ? [{}] :
    flatten([for idx, vm in var.naming.virtualmachine_names.WEB_SECONDARY_DNSNAME :
      {
        var.naming.virtualmachine_names.WEB_SECONDARY_DNSNAME[idx] = azurerm_network_interface.web[idx].private_ip_address
      }
      ]
    )
  )
}

output "dns_info_loadbalancers" {
  value = [
    { format("%s%s%s", local.prefix, var.naming.separator, "scs") = azurerm_lb.scs[0].private_ip_addresses[0] },
    { format("%s%s%s", local.prefix, var.naming.separator, "ers") = azurerm_lb.scs[0].private_ip_addresses[1] },
    { format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.web_alb) = azurerm_lb.web[0].private_ip_addresses[0] }
  ]
}
