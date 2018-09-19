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

variable "nic_id" {
  description = "The id of the network interface that should be associated with this vm."
}

variable "vm_size" {
  description = "The size of the VM to create."
}

variable "vm_user" {
  description = "The username of your vm."
}

variable "availability_set_id" {
  description = "The if associated with the availability set to put this vm into."
  default     = ""
}

variable "machine_name" {
  description = "The name for the vm that is being created."
}

variable "machine_type" {
  description = "The use of the vm to help later with configurations."
}

variable "tags" {
  type        = "map"
  description = "tags to add to the machine"
  default     = {}
}
