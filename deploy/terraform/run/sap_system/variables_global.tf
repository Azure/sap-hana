variable "application" {
  description = "Details of the Application layer"
  default     = {}
}

variable "databases" {
  description = "Details of the HANA database nodes"
  default     = []
}

variable "infrastructure" {
  description = "Details of the Azure infrastructure to deploy the SAP landscape into"
  default     = {}
}

variable "options" {
  description = "Configuration options"
  default     = {}
}

variable "software" {
  description = "Contain information about downloader, sapbits, etc."
  default     = {}
}

variable "ssh-timeout" {
  description = "Timeout for connection that is used by provisioner"
  default     = "30s"
}

variable "sshkey" {
  description = "Details of ssh key pair"
  default     = {}
}
