variable "jumpboxes" {
  description = "Details of the jumpboxes"
}

variable "infrastructure" {
  description = "Details of the Azure infrastructure to deploy the SAP landscape into"
}

variable "rg" {
  description = "Details of the resource group"
}

variable "subnet-mgmt" {
  description = "Details of the management subnet"
}

variable "nsg-mgmt" {
  description = "Details of the management nsg"
}
