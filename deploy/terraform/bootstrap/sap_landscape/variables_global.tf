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

variable "jumpboxes" {
  description = "Details of the jumpboxes and RTI box"
}

variable "options" {
  description = "Configuration options"
  default     = {}
}

variable "software" {
  description = "Details of the infrastructure components required for SAP installation"
}

variable "ssh-timeout" {
  description = "Timeout for connection that is used by provisioner"
  default     = "30s"
}

variable "sshkey" {
  description = "Details of ssh key pair"
  default = {
    path_to_public_key  = "~/.ssh/id_rsa.pub",
    path_to_private_key = "~/.ssh/id_rsa"
  }
}
