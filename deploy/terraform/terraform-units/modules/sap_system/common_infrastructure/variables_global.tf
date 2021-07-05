variable "application" {
  validation {
    condition = (
      length(trimspace(try(var.application.sid, ""))) != 0
    )
    error_message = "The sid must be specified in the application.sid field."
  }

}
variable "databases" {
  validation {
    condition = (
      length(trimspace(try(var.databases[0].platform, ""))) != 7
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
      length(trimspace(try(var.infrastructure.vnets.sap.name, ""))) != 0
    )
    error_message = "Please specify the logical VNet identifier in the infrastructure.vnets.sap.name field. For deployments prior to version '2.3.3.1' please use the identifier 'sap'."
  }

  validation {
    condition = (
      contains(keys(var.infrastructure.vnets.sap), "subnet_admin") ? (
        var.infrastructure.vnets.sap.subnet_admin != null ? (
          length(trimspace(try(var.infrastructure.vnets.sap.subnet_admin.arm_id, ""))) != 0 || length(trimspace(try(var.infrastructure.vnets.sap.subnet_admin.prefix, ""))) != 0) : (
          true
        )) : (
        true
      )
    )
    error_message = "Either the arm_id or prefix of the Admin subnet must be specified in the infrastructure.vnets.sap.subnet_admin block."
  }

  validation {
    condition = (
      contains(keys(var.infrastructure.vnets.sap), "subnet_app") ? (
        var.infrastructure.vnets.sap.subnet_app != null ? (
          length(trimspace(try(var.infrastructure.vnets.sap.subnet_app.arm_id, ""))) != 0 || length(trimspace(try(var.infrastructure.vnets.sap.subnet_app.prefix, ""))) != 0) : (
          true
        )) : (
        true
      )
    )
    error_message = "Either the arm_id or prefix of the Application subnet must be specified in the infrastructure.vnets.sap.subnet_app block."
  }

  validation {
    condition = (
      contains(keys(var.infrastructure.vnets.sap), "subnet_db") ? (
        var.infrastructure.vnets.sap.subnet_db != null ? (
          length(trimspace(try(var.infrastructure.vnets.sap.subnet_db.arm_id, ""))) != 0 || length(trimspace(try(var.infrastructure.vnets.sap.subnet_db.prefix, ""))) != 0) : (
          true
        )) : (
        true
      )
    )
    error_message = "Either the arm_id or prefix of the Database subnet must be specified in the infrastructure.vnets.sap.subnet_db block."
  }

}

variable "options" {}
variable "authentication" {}
variable "key_vault" {
  validation {
    condition = (
      contains(keys(var.key_vault), "kv_spn_id") ? (
        length(var.key_vault.kv_spn_id) > 0 ? (
          length(split("/", var.key_vault.kv_spn_id)) == 9) : (
          true
        )) : (
        true
      )
    )
    error_message = "If specified, the kv_spn_id needs to be a correctly formed Azure resource ID."
  }
  validation {
    condition = (
      contains(keys(var.key_vault), "kv_user_id") ? (
        length(var.key_vault.kv_user_id) > 0 ? (
          length(split("/", var.key_vault.kv_user_id)) == 9) : (
          true
        )) : (
        true
      )
    )
    error_message = "If specified, the kv_user_id needs to be a correctly formed Azure resource ID."
  }

  validation {
    condition = (
      contains(keys(var.key_vault), "kv_prvt_id") ? (
        length(var.key_vault.kv_prvt_id) > 0 ? (
          length(split("/", var.key_vault.kv_prvt_id)) == 9) : (
          true
        )) : (
        true
      )
    )
    error_message = "If specified, the kv_prvt_id needs to be a correctly formed Azure resource ID."
  }


}
