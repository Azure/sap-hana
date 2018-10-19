# This is how we call Ansible and pass in variables from Terraform.
resource null_resource "mount-disks-and-configure-hana" {
  provisioner "local-exec" {
    command = <<EOT
    OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES \
    AZURE_RESOURCE_GROUPS="${var.az_resource_group}" \
    ANSIBLE_HOST_KEY_CHECKING="False" \
    ansible-playbook -u ${var.vm_user} \
    --private-key '${var.sshkey_path_private}' \
    --extra-vars="{ \"url_sapcar\": \"${var.url_sap_sapcar}\", \
     \"url_hdbserver\": \"${var.url_sap_hdbserver}\", \
     \"sap_sid\": \"${var.sap_sid}\", \
     \"sap_instancenum\": \"${var.sap_instancenum}\", \
     \"pwd_os_sapadm\": \"${var.pw_os_sapadm}\", \
     \"pwd_os_sidadm\": \"${var.pw_os_sidadm}\", \
     \"pwd_db_system\": \"${var.pw_db_system}\", \
     \"pwd_hacluster\": \"${var.pw_hacluster}\", \
     \"use_hana2\": \"${var.useHana2}\", \
     \"db_num\": \"${var.db_num}\", \
     \"db0_ip\": \"${var.private_ip_address_db0}\", \
     \"db1_ip\": \"${var.private_ip_address_db1}\", \
     \"lb_frontend_ip\": \"${var.private_ip_address_lb_frontend}\", \
     \"resource_group\": \"${var.az_resource_group}\", \
     \"url_xsa_runtime\": \"${var.url_xsa_runtime}\", \
     \"url_di_core\": \"${var.url_di_core}\", \
     \"url_sapui5\": \"${var.url_sapui5}\", \
     \"url_portal_services\": \"${var.url_portal_services}\", \
     \"url_xs_services\": \"${var.url_xs_services}\", \
     \"url_shine_xsa\": \"${var.url_shine_xsa}\", \
     \"url_sapcar_windows\": \"${var.url_sapcar_windows}\", \
     \"url_hana_studio_windows\": \"${var.url_hana_studio_windows}\", \
     \"pwd_db_xsaadmin\": \"${var.pwd_db_xsaadmin}\", \
     \"pw_bastion_windows\": \"${var.pw_bastion_windows}\", \
     \"bastion_username_windows\": \"${var.bastion_username_windows}\", \
     \"pwd_db_tenant\": \"${var.pwd_db_tenant}\", \
     \"pwd_db_shine\": \"${var.pwd_db_shine}\", \
     \"email_shine\": \"${var.email_shine}\", \
     \"install_xsa\": ${var.install_xsa}, \
     \"install_shine\": ${var.install_shine}, \
     \"install_cockpit\": ${var.install_cockpit}, \
     \"url_cockpit\": \"${var.url_cockpit}\" , \
     \"azure_service_principal_id\": \"${var.azure_service_principal_id}\", \
     \"azure_service_principal_pw\": \"${var.azure_service_principal_pw}\" }" \
     -i '../../ansible/azure_rm.py' ${var.ansible_playbook_path}
     EOT

    environment {
      HOSTS = "${var.vms_configured}"
    }
  }
}
