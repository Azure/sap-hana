variable "application" {
  description = "Details of the Application layer"
  default = {
    enable_deployment        = true
    use_DHCP                 = false
    application_server_count = 0
    dual_nics                = false
  }


}

variable "databases" {
  description = "Details of the HANA database nodes"
  default = [
    {
      use_DHCP = false

    }
  ]

}

variable "infrastructure" {
  description = "Details of the Azure infrastructure to deploy the SAP landscape into"
  default     = {}

}

variable "options" {
  description = "Configuration options"
  default = {
    resource_offset   = 0
    nsg_asg_with_vnet = false
    legacy_nic_order  = false
  }
}

variable "software" {
  description = "Contain information about downloader, sapbits, etc."
  default     = {}
}

variable "ssh-timeout" {
  description = "Timeout for connection that is used by provisioner"
  default     = "30s"
}

variable "key_vault" {
  description = "Details of keyvault"
  default     = {}

}

variable "authentication" {
  description = "Defining the SDU credentials"
  default = {
  }
}
