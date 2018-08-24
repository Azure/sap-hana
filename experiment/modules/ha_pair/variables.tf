variable "az_region" {}

variable "vm_user" {
  description = "The username of your HANA db vm."
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

variable "url_sap_hdbserver" {
  type        = "string"
  description = "The url that points to the HDB server 122.17 bits"
}

variable "private_ip_address_db0" {
  default = "10.0.0.6"
}

variable "private_ip_address_db1" {
  default = "10.0.0.7"
}

variable "private_ip_address_iscsi" {
  default = "10.0.0.17"
}

variable "public_ip_allocation_type" {
  description = "Defines whether the IP address is static or dynamic. Options are Static or Dynamic."
  default     = "dynamic"
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
  description = "A boolean that will choose between HANA 1.0 and 2.0"
  default     = false
}

variable "storage_disk_sizes_gb" {
  description = "List disk sizes in GB for all disks this VM will need"
  default     = [512, 512, 512]
}

locals {
  # These are the load balancing ports specifically for HANA1 pacemaker. DO NOT ALTER
  hana1_lb_ports = [
    "3${var.sap_instancenum}15",
    "3${var.sap_instancenum}17",
  ]

  # These are the load balancing ports specifically for HANA2 pacemaker. DO NOT ALTER
  hana2_lb_ports = [
    "3${var.sap_instancenum}13",
    "3${var.sap_instancenum}14",
    "3${var.sap_instancenum}40",
    "3${var.sap_instancenum}41",
    "3${var.sap_instancenum}42",
  ]
}
