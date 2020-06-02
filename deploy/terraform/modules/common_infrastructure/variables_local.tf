variable "is_single_node_hana" {
  description = "Checks if single node hana architecture scenario is being deployed"
  default     = false
}

locals {

  # Filter the list of databases to only HANA platform entries
  hana-databases = [
    for database in var.databases : database
    if database.platform == "HANA"
  ]

  # iSCSI target device(s) is only created when below conditions met:
  # - iscsi is defined in input JSON
  # - AND
  #   - HANA database has high_availability set to true
  #   - HANA database uses SUSE
  iscsi_count = lookup(var.infrastructure, "iscsi", {}) != {} && (length(local.hana-databases) > 0 ? (local.hana-databases[0].high_availability && upper(local.hana-databases[0].os.publisher) == "SUSE") : false) ? var.infrastructure.iscsi.iscsi_count : 0

  # Shortcut to iSCSI definition
  iscsi = merge(lookup(var.infrastructure, "iscsi", {}), { "iscsi_count" = "${local.iscsi_count}" })

  # Shortcut to subnet block for iSCSI in input JSON
  subnet_iscsi = merge({ "is_existing" = "false" }, lookup(var.infrastructure.vnets.sap, "subnet_iscsi", {}))
}
