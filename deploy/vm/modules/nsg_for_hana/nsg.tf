resource null_resource "create-nsg" {
  count = "${var.use_existing_nsg ? 0 : 1}"

  provisioner "local-exec" {
    command = <<EOT
              ansible-playbook \
	            --extra-vars="{ \"sap_instancenum\": \"${var.sap_instancenum}\", \
              \"allow_ips\": ${length(var.allow_ips) > 0 ? jsonencode(var.allow_ips): local.all_ips}, \
              \"hana_nsg_name\": \"${var.nsg_name}\", \
              \"install_xsa\": ${var.install_xsa}, \
              \"az_resource_group_name\": \"${var.resource_group_name}\" }" \
              ../../ansible/create_nsg.yml
EOT
  }
}

resource null_resource "destroy-nsg" {
  count = "${var.use_existing_nsg ? 0 : 1}"

  provisioner "local-exec" {
    when = "destroy"

    command = <<EOT
              ansible-playbook \
	            --extra-vars="{ \"sap_instancenum\": \"${var.sap_instancenum}\", \
              \"allow_ips\": ${length(var.allow_ips) > 0 ? jsonencode(var.allow_ips): local.all_ips}, \
              \"hana_nsg_name\": \"${var.nsg_name}\", \
              \"install_xsa\": ${var.install_xsa}, \
              \"az_resource_group_name\": \"${var.resource_group_name}\" }" \
              ../../ansible/delete_nsg.yml
EOT
  }
}
