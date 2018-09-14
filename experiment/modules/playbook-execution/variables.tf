variable "ansible_playbook_path" {
  description = "Path from this module to the playbook"
}

variable "az_resource_group" {
  description = "Which azure resource group to deploy the HANA setup into.  i.e. <myResourceGroup>"
}

variable "vm_user" {
  description = "The username of your HANA db vm."
}

variable "sshkey_path_private" {
  description = "The path on the local machine to where the private key is"
}

variable "sap_sid" {
  default = "PV1"
}

variable "sap_instancenum" {
  description = "The sap instance number which is in range 00-99"
}

variable "url_sap_sapcar" {
  type        = "string"
  description = "The url that points to the SAPCAR bits"
}

variable "url_sap_hdbserver" {
  type        = "string"
  description = "The url that points to the HDB server 122.17 bits"
}

variable "private_ip_address_db0" {
  description = "Private ip address of db0 in HA pair"
  default     = ""                                     # not needed in single node case
}

variable "private_ip_address_db1" {
  description = "Private ip address of db1 in HA pair"
  default     = ""                                     # not needed in single node case
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

variable "pw_db_system" {
  description = "Password for the database user SYSTEM"
}

variable "useHana2" {
  description = "If this is set to true, then, ports specifically for HANA 2.0 will be opened."
  default     = false
}

variable "vms_configured" {
  description = "The hostnames of the machines that need to be configured in order to correctly run this playbook."
}

variable "url_xsa_runtime" {
  description = "URL for XSA runtime"
}

variable "url_di_core" {
  description = "URL for DI Core"
}

variable "url_sapui5" {
  description = "URL for SAPUI5"
}

variable "url_portal_services" {
  description = "URL for Portal Services"
}

variable "url_xs_services" {
  description = "URL for XS Services"
}

variable "url_shine_xsa" {
  description = "URL for SHINE XSA"
}

variable "pwd_db_xsaadmin" {
  description = "Password for XSAADMIN user"
}

variable "pwd_db_tenant" {
  description = "Password for SYSTEM user (tenant DB)"
}

variable "pwd_db_shine" {
  description = "Password for SHINE user"
}

variable "email_shine" {
  description = "e-mail address for SHINE user"
}
