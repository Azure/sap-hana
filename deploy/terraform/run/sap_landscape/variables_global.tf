variable "infrastructure" {
  description = "Details of the Azure infrastructure to deploy the SAP landscape into"
  default     = {}
}

variable "options" {
  description = "Configuration options"
  default     = {}
}

variable "ssh-timeout" {
  description = "Timeout for connection that is used by provisioner"
  default     = "30s"
}

variable "sshkey" {
  description = "Details of ssh key pair"
  default = {
  }
  validation {
    condition = (
      length(var.sshkey) > 1
    )
    error_message = "Either ssh keys or user credentials must be specified."
  }
  validation {
    condition = (
      length(trimspace(var.sshkey.username)) != 0
    )
    error_message = "The default username for the Virtual machines must be specified."
  }
}

variable "key_vault" {
  description = "The user brings existing Azure Key Vaults"
  default = {
    kv_user_id = "",
    kv_prvt_id = "",
  }
}

