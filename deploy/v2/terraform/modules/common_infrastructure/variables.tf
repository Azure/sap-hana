variable "infrastructure" {
  description = "Details of the Azure infrastructure to deploy the SAP landscape into"
}

variable "is_single_node_hana" {
  description = "Checks if single node hana architecture scenario is being deployed"
  default     = false
}

variable "software" {
  description = "Details of the infrastructure components required for SAP installation"
}

variable "options" {
  description = "Configuration options"
}
