variable "ansible_playbook_path" {
  description = "Path from this module to the playbook"
}

variable "az_resource_group" {
  description = "Which azure resource group to deploy the HANA setup into.  i.e. <myResourceGroup>"
}

variable "bastion_username_windows" {
  description = "The username for the bastion host"
}

variable "db_num" {
  description = "which node is currently being created"
  default     = 0
}

variable "email_shine" {
  description = "e-mail address for SHINE user"
  default     = "shinedemo@microsoft.com"
}

variable "install_cockpit" {
  description = "Flag to determine whether to install Cockpit on the host VM"
  default     = false
}

variable "install_shine" {
  description = "Flag to determine whether to install SHINE on the host VM"
  default     = false
}

variable "install_xsa" {
  description = "Flag to determine whether to install XSA on the host VM"
  default     = false
}

variable "private_ip_address_db0" {
  description = "Private ip address of db0 in HA pair"
  default     = ""                                     # not needed in single node case
}

variable "private_ip_address_db1" {
  description = "Private ip address of db1 in HA pair"
  default     = ""                                     # not needed in single node case
}

variable "private_ip_address_lb_frontend" {
  description = "Private ip address of the load balancer front end in HA pair"
  default     = ""                                                             # not needed in single node case
}

variable "pw_bastion_windows" {
  description = "The password for the bastion host"
}

variable "pw_db_system" {
  description = "Password for the database user SYSTEM"
}

variable "pw_hacluster" {
  type        = "string"
  description = "Password for the HA cluster nodes"
  default     = ""                                  #single node case doesn't need one
}

variable "pw_os_sapadm" {
  description = "Password for the SAP admin, which is an OS user"
}

variable "pw_os_sidadm" {
  description = "Password for this specific sidadm, which is an OS user"
}

variable "pwd_db_shine" {
  description = "Password for SHINE user"
  default     = ""
}

variable "pwd_db_tenant" {
  description = "Password for SYSTEM user (tenant DB)"
  default     = ""
}

variable "pwd_db_xsaadmin" {
  description = "Password for XSAADMIN user"
  default     = ""
}

variable "sap_instancenum" {
  description = "The SAP instance number which is in range 00-99"
}

variable "sap_sid" {
  default = "PV1"
}

variable "sshkey_path_private" {
  description = "The path on the local machine to where the private key is"
}

variable "url_cockpit" {
  description = "URL for HANA Cockpit"
  default     = ""
}

variable "url_di_core" {
  description = "URL for DI Core"
  default     = ""
}

variable "url_hana_studio_windows" {
  description = "URL for the Windows version of HANA Studio to install on the bastion host"
}

variable "url_portal_services" {
  description = "URL for Portal Services"
  default     = ""
}

variable "url_sap_hdbserver" {
  type        = "string"
  description = "The URL that points to the HDB server 122.17 bits"
}

variable "url_sap_sapcar" {
  type        = "string"
  description = "The URL that points to the SAPCAR bits"
}

variable "url_sapcar_windows" {
  description = "URL for SAPCAR for Windows to run on the bastion host"
}

variable "url_sapui5" {
  description = "URL for SAPUI5"
  default     = ""
}

variable "url_shine_xsa" {
  description = "URL for SHINE XSA"
  default     = ""
}

variable "url_xs_services" {
  description = "URL for XS Services"
  default     = ""
}

variable "url_xsa_runtime" {
  description = "URL for XSA runtime"
  default     = ""
}

variable "useHana2" {
  description = "If this is set to true, then, ports specifically for HANA 2.0 will be opened."
  default     = false
}

variable "vm_user" {
  description = "The username of your HANA database VM."
}

variable "vms_configured" {
  description = "The hostnames of the machines that need to be configured in order to correctly run this playbook."
}

variable "azure_service_principal_id" {
  description = "Service principal Id"
}

variable "azure_service_principal_pw" {
  description = "service principal password"
}
