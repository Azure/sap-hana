output "nsg-name" {
  depends_on = ["null_resource.create-nsg"]
  value      = "${var.nsg_name}"
}

# output "nsg-name" {
#   value = "${element(concat(azurerm_network_security_group.sap-nsg.*.name,list(local.empty_string)),0)}"
# }

