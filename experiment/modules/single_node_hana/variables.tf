variable "az_region" {}

variable "vm_user" {
  description = "The username of your HANA db vm."
}

variable "az_domain_name" {
  description = "A name that is used to access your HANA vm"
}

variable "sshkey_path_private" {
  description = "The path on the local machine to where the private key is"
}

variable "sshkey_path_public" {
  description = "The path on the local machine to where the public key is"
}

variable "az_resource_group" {
  description = "Which azure resource group to deploy the HANA setup into.  i.e. <myResourceGroup>"
}

variable "sap_sid" {
  default = "PV1"
}

variable "sap_instancenum" {
  description = "The sap instance number which is in range 00-99"
}

variable "db_num" {
  description = "which node is currently being created"
}

variable "vm_size" {
  default = "Standard_E8s_v3"
}

variable "url_sap_sapcar" {
  type        = "string"
  description = "The url that points to the SAPCAR bits"
}

variable "url_sap_hostagent" {
  type        = "string"
  description = "The url that points to the sap host agent 36 bits"
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

variable "nsg_id" {
  description = "The nsg id for the nsg that will control this vm."
}

variable "hana_subnet_id" {
  description = "The hana specific subnet that this node needs to be on"
}

variable "storage_disk_sizes_gb" {
  description = "List disk sizes in GB for all disks this VM will need"
  default     = [512, 512, 512]
}

variable "useHana2" {
  description = "If this is set to true, then, ports specifically for HANA 2.0 will be opened."
  default     = false
}

locals {
  vm_fqdn = "${azurerm_public_ip.hdb-pip.fqdn}"
  vm_name = "${var.sap_sid}-db${var.db_num}"
}
