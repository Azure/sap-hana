output "nsg-name" {
  depends_on = ["null_resource.create-nsg"]
  value      = "${var.nsg_name}"
}
