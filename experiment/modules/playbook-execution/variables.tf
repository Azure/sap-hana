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
