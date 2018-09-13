resource null_resource "mount-disks-and-configure-hana" {
  provisioner "local-exec" {
    command = <<EOT
    AZURE_RESOURCE_GROUPS="${var.az_resource_group}" \
    ANSIBLE_HOST_KEY_CHECKING="False" \
    ansible-playbook -u ${var.vm_user} \
    --private-key '${var.sshkey_path_private}' \
    --extra-vars="{\"url_sapcar\": \"${var.url_sap_sapcar}\",\
     \"url_hdbserver\": \"${var.url_sap_hdbserver}\", \
     \"sap_sid\": \"${var.sap_sid}\", \
     \"sap_instancenum\": \"${var.sap_instancenum}\", \
     \"pwd_os_sapadm\": \"${var.pw_os_sapadm}\", \
     \"pwd_os_sidadm\": \"${var.pw_os_sidadm}\", \
     \"pwd_db_system\": \"${var.pw_db_system}\", \
     \"pwd_hacluster\": \"${var.pw_hacluster}\", \
     \"use_hana2\": \"${var.useHana2}\", \
     \"db0_ip\": \"${var.private_ip_address_db0}\", \
     \"db1_ip\": \"${var.private_ip_address_db1}\", \
     \"resource_group\": \"${var.az_resource_group}\" }" \
     -i '../../ansible/azure_rm.py' ${var.ansible_playbook_path}
     EOT

    environment {
      HOSTS = "${var.vms_configured}"
    }
  }
}
