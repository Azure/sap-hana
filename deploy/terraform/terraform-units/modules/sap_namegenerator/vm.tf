locals {

  db_oscode       = upper(var.db_ostype) == "LINUX" ? "l" : "w"
  app_oscode      = upper(var.app_ostype) == "LINUX" ? "l" : "w"
  db_platformcode = substr(var.db_platform, 0, 3)

 deployer_vm_names = [for idx in range(var.app_server_count) :
    lower(format("%s%s%sdeploy%02d", local.env_verified, local.location_short, local.dep_vnet_verified, idx))
  ]

  anydb_server_names = [for idx in range(var.db_server_count) :
    format("%sd%s%02dl%d%s", lower(var.sap_sid), lower(var.db_sid), idx, 0, local.random_id_vm_verified)
    ]

  anydb_server_names_ha =  [for idx in range(var.db_server_count) :
      format("%sd%s%02dl%d%s", lower(var.sap_sid), lower(var.db_sid), idx, 1, local.random_id_vm_verified)
    ]

  app_server_names = [for idx in range(var.app_server_count) :
    format("%sapp%02d%s%s", lower(var.sap_sid), idx, local.app_oscode, local.random_id_vm_verified)
  ]

  iscsi_server_names = [for idx in range(var.iscsi_server_count) :
    lower(format("%s%s%siscsi%02d", lower(local.env_verified), local.vnet_verified, local.location_short , idx))
  ]

  hana_server_names = [for idx in range(var.db_server_count) :
    format("%sd%s%02dl%d%s", lower(var.sap_sid), lower(var.db_sid), idx, 0, local.random_id_vm_verified)
    ]

  hana_server_names_ha = [for idx in range(var.db_server_count) :
      format("%sd%s%02dl%d%s", lower(var.sap_sid), lower(var.db_sid), idx, 1, local.random_id_vm_verified)
    ]

  scs_server_names = [for idx in range(var.scs_server_count) :
    format("%sscs%02d%s%s", lower(var.sap_sid), idx, local.app_oscode, local.random_id_vm_verified)
  ]

  web_server_names = [for idx in range(var.web_server_count) :
    format("%sweb%02d%s%s", lower(var.sap_sid), idx, local.app_oscode, local.random_id_vm_verified)
  ]

}
