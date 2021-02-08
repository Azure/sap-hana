variable "application" {
  description = "Details of the Application layer"
  default     = {}
  
  validation {
    condition = (
      length(trimspace(try(var.application.sid, ""))) != 0
    )
    error_message = "The sid must be specified in the application.sid field."
  }

}

variable "databases" {
  description = "Details of the HANA database nodes"
  default     = []
  
  validation {
    condition = (
      length(trimspace(try(var.databases[0].platform, ""))) != 0
    )
    error_message = "The platform (HANA, SQLSERVER, ORACLE, DB2) must be specified in the databases block."
  }

  validation {
    condition = (
      length(trimspace(try(var.databases[0].size, ""))) != 0
    )
    error_message = "The size must be specified in the databases block."
  }

}

variable "infrastructure" {
  description = "Details of the Azure infrastructure to deploy the SAP landscape into"
  default     = {}
  
  validation {
    condition = (
      length(trimspace(try(var.infrastructure.region, ""))) != 0
    )
    error_message = "The region must be specified in the infrastructure.region field."
  }

  validation {
    condition = (
      length(trimspace(try(var.infrastructure.environment, ""))) != 0
    )
    error_message = "The environment must be specified in the infrastructure.environment field."
  }

  validation {
    condition = (
      length(trimspace(try(var.infrastructure.vnets.sap.subnet_admin.arm_id, ""))) != 0 || length(trimspace(try(var.infrastructure.vnets.sap.subnet_admin.prefix, ""))) != 0
    )
    error_message = "Either the arm_id or prefix of the Admin subnet must be specified in the infrastructure.vnets.sap.subnet_admin block."
  }

  validation {
    condition = (
      length(trimspace(try(var.infrastructure.vnets.sap.subnet_app.arm_id, ""))) != 0 || length(trimspace(try(var.infrastructure.vnets.sap.subnet_app.prefix, ""))) != 0
    )
    error_message = "Either the arm_id or prefix of the Application subnet must be specified in the infrastructure.vnets.sap.subnet_app block."
  }

  validation {
    condition = (
      length(trimspace(try(var.infrastructure.vnets.sap.subnet_db.arm_id, ""))) != 0 || length(trimspace(try(var.infrastructure.vnets.sap.subnet_db.prefix, ""))) != 0
    )
    error_message = "Either the arm_id or prefix of the Database subnet must be specified in the infrastructure.vnets.sap.subnet_db block."
  }
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

variable "key_vault" {
  description = "Details of keyvault"
  default     = {}
}

variable "authentication" {
  description = "Defining the SDU credentials"
  default = {
  }
}
