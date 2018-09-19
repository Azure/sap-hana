variable "az_region" {}

variable "az_resource_group" {
  description = "Which azure resource group to deploy the HANA setup into.  i.e. <myResourceGroup>"
}

variable "storage_disk_sizes_gb" {
  type        = "list"
  description = "List disk sizes in GB for all disks this VM will need"
}

variable "sshkey_path_public" {
  description = "The path on the local machine to where the public key is"
}

variable "sap_sid" {
  default = "PV1"
}

variable "vm_size" {
  default = "Standard_E8s_v3"
}

variable "vm_user" {
  description = "The username of your HANA db vm."
}

variable "availability_set_id" {
  description = "The if associated with the availability set to put this vm into."
  default     = ""
}

variable "db_num" {
  description = "which node is currently being created"
}

variable "hana_subnet_id" {
  description = "The hana specific subnet that this node needs to be on"
}

variable "nsg_id" {
  description = "The nsg id for the nsg that will control this vm."
}

variable "backend_ip_pool_ids" {
  type        = "list"
  description = "The ids that associate the load balancer's back end ip pool with this nic."
  default     = []
}

variable "private_ip_address" {
  description = "The desired private ip address of this nic.  If it isn't specified, a dynamic ip will be allocated."
  default     = ""
}

variable "public_ip_allocation_type" {
  description = "Defines whether the IP address is static or dynamic. Options are Static or Dynamic."
}

locals {
  vm_db_name   = "db${var.db_num}"
  machine_name = "${lower(var.sap_sid)}-db${var.db_num}"
}
