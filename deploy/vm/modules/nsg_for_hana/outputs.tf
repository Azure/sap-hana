output "nsg-name" {
  depends_on = ["null_resource.create-nsg", "null_resource.destroy-nsg"]
  value      = "${var.nsg_name}"
}
