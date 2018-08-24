variable "az_region" {}

variable "az_resource_group" {
  description = "Which azure resource group to deploy the HANA setup into.  i.e. <myResourceGroup>"
}

variable "name" {
  description = "A name that will be used to identify the resource this nic and pip are related to."
}

variable "subnet_id" {
  description = "The subnet that this node needs to be on"
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
  empty_string = ""
  static       = "static"
  dynamic      = "dynamic"
}
