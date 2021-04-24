##################################################################################################################
# OUTPUT Files
##################################################################################################################

# Generates the output JSON with IP address and disk details
/*
resource "local_file" "output_json" {
  content = jsonencode({
    "infrastructure" = merge(var.infrastructure_w_defaults, { "iscsi" = { "iscsi_nic_ips" = [local.ips_iscsi] } })
    "databases" = flatten([
      [
        for database in local.databases : {
          platform          = database.platform,
          db_version        = database.db_version,
          os                = database.os,
          size              = database.size,
          filesystem        = database.filesystem,
          high_availability = database.high_availability,
          instance          = database.instance,
          authentication    = database.authentication,
          credentials       = database.credentials,
          components        = database.components,
          xsa               = database.xsa,
          shine             = database.shine,

          nodes = [for ip_dbnode_admin in local.ips_dbnodes_admin : {
            // Hostname is required for Ansible, therefore set dbname from resource name to hostname
            dbname       = replace(local.hdb_vms[index(local.ips_dbnodes_admin, ip_dbnode_admin)].name, "_", "")
            ip_admin_nic = ip_dbnode_admin,
            ip_db_nic    = local.ips_dbnodes_db[index(local.ips_dbnodes_admin, ip_dbnode_admin)]
            role         = local.hdb_vms[index(local.ips_dbnodes_admin, ip_dbnode_admin)].role
            } if local.hdb_vms[index(local.ips_dbnodes_admin, ip_dbnode_admin)].platform == database.platform
          ],
          loadbalancer = {
            frontend_ip = var.loadbalancers[0].private_ip_address
          }
        }
        if database != {}
      ],
      [
        for database in local.anydatabases : {
          platform          = database.platform,
          db_version        = database.db_version,
          os                = database.os,
          size              = database.size,
          filesystem        = database.filesystem,
          high_availability = database.high_availability,
          authentication    = database.authentication,
          credentials       = database.credentials,
          nodes = [for ip_anydbnode in local.ips_anydbnodes : {
            # Check for maximum length and for "_"
            dbname    = substr(replace(local.anydb_vms[index(local.ips_anydbnodes, ip_anydbnode)].name, "_", ""), 0, 13)
            ip_db_nic = local.ips_anydbnodes[index(local.ips_anydbnodes, ip_anydbnode)],
            role      = local.anydb_vms[index(local.ips_anydbnodes, ip_anydbnode)].role
            } if upper(local.anydb_vms[index(local.ips_anydbnodes, ip_anydbnode)].platform) == upper(database.platform)
          ],
          loadbalancer = {
            frontend_ip = var.anydb_loadbalancers[0].private_ip_address
          }
        }
        if database != {}
      ]
      ]
    ),
    "software" = merge(
      { "downloader" = local.downloader },
      { "storage_account_sapbits" = {
        name                = ""
        storage_access_key  = ""
        file_share_name     = ""
        blob_container_name = ""
        }
      }
    ),
    "options" = var.options
    }
  )
  filename             = "${path.cwd}/ansible_config_files/output.json"
  file_permission      = "0660"
  directory_permission = "0770"
}

# Generates the Ansible Inventory file
resource "local_file" "ansible_inventory" {
  content = templatefile(path.module/ansible_inventory.tmpl, {
    iscsi             = local.iscsi,
    ips_iscsi         = local.ips_iscsi,
    ips_dbnodes_admin = local.ips_dbnodes_admin,
    ips_dbnodes_db    = local.ips_dbnodes_db,
    dbnodes           = local.hdb_vms,
    application       = var.application,
    ips_scs           = local.ips_scs,
    ips_app           = local.ips_app,
    ips_web           = local.ips_web
    anydbnodes        = local.anydb_vms,
    ips_anydbnodes    = local.ips_anydbnodes
    }
  )
  filename             = "${path.cwd}/ansible_config_files/hosts"
  file_permission      = "0660"
  directory_permission = "0770"
}

# Generates the Ansible Inventory file
resource "local_file" "ansible_inventory_yml" {
  content = templatefile(path.module/ansible_inventory.yml.tmpl", {
    iscsi             = local.iscsi,
    ips_iscsi         = local.ips_iscsi,
    ips_dbnodes_admin = local.ips_dbnodes_admin,
    ips_dbnodes_db    = local.ips_dbnodes_db,
    dbnodes           = local.hdb_vms,
    application       = var.application,
    ips_scs           = local.ips_scs,
    ips_app           = local.ips_app,
    ips_web           = local.ips_web
    anydbnodes        = local.anydb_vms,
    ips_anydbnodes    = local.ips_anydbnodes,
    }
  )
  filename             = "${path.cwd}/ansible_config_files/hosts.yml"
  file_permission      = "0660"
  directory_permission = "0770"
}
*/
resource "local_file" "ansible_inventory_new_yml" {
  content = templatefile(format("%s%s",path.module,"/ansible_inventory_new.yml.tmpl"), {
    ips_dbnodes       = length(local.hdb_vms) > 0 ? local.ips_dbnodes_admin : local.ips_anydbnodes,
    dbnodes           = length(local.hdb_vms) > 0 ? local.hdb_vms : local.anydb_vms
    ips_scs           = local.ips_scs,
    ips_pas           = length(local.ips_app) > 0 ? slice(local.ips_app, 0, 1) : [],
    ips_app           = length(local.ips_app) > 1 ? slice(local.ips_app, 1, length(local.ips_app) - 1) : []
    ips_web           = length(local.ips_web) > 0 ? local.ips_web : [],
    sid               = var.hdb_sid,
    passervers        = length(local.ips_app) > 0 ? slice(var.naming.virtualmachine_names.APP_VMNAME, 0, 1) : [],
    appservers        = length(local.ips_app) > 1 ? slice(var.naming.virtualmachine_names.APP_VMNAME, 1, length(local.ips_app)) : [],
    scsservers        = length(local.ips_scs) > 0 ? var.naming.virtualmachine_names.SCS_VMNAME : [],
    webservers        = length(local.ips_web) > 0 ? var.naming.virtualmachine_names.WEB_VMNAME : [],
    prefix            = var.naming.prefix.SDU,
    separator         = var.naming.separator,
    platform          = length(local.hdb_vms) > 0 ? "HANA" : local.anydb_vms[0].platform
    dbconnection      = length(local.hdb_vms) > 0 ? "ssh" : upper(local.anydb_vms[0].platform) == "SQLSERVER" ? "winrm" : "ssh"
    scsconnection     = upper(var.app_tier_os_types["scs"]) == "LINUX" ? "ssh" : "winrm"
    appconnection     = upper(var.app_tier_os_types["app"]) == "LINUX" ? "ssh" : "winrm"
    webconnection     = upper(var.app_tier_os_types["web"]) == "LINUX" ? "ssh" : "winrm"
    appconnectiontype = var.application.auth_type
    webconnectiontype = var.application.auth_type
    scsconnectiontype = var.application.auth_type
    dbconnectiontype  = length(local.hdb_vms) > 0 ? local.hdb_vms[0].auth_type : local.anydb_vms[0].auth_type
    }
  )
  filename             = format("%s/ansible_config_files/%s_hosts.yaml",path.cwd,var.hdb_sid)
  file_permission      = "0660"
  directory_permission = "0770"
}

resource "local_file" "sap-parameters_yml" {
  content = templatefile(format("%s/sap-parameters.yml.tmpl",path.module), {
    sid          = var.hdb_sid,
    environment  = var.infrastructure.environment,
    kv_uri       = local.kv_name,
    uname_secret = local.uname_secret,
    pwd_secret   = local.pwd_secret,
    key_secret   = local.key_secret
    disks        = var.disks
    }
  )
  filename             = format("%s/ansible_config_files/sap-parameters.yaml",path.cwd)
  file_permission      = "0660"
  directory_permission = "0770"
}


resource "azurerm_storage_blob" "hosts_yaml" {
  provider               = azurerm.deployer
  name                   = format("%s_hosts.yml", trimspace(var.naming.prefix.SDU))
  storage_account_name   = local.tfstate_storage_account_name
  storage_container_name = local.ansible_container_name
  type                   = "Block"
  source                 = local_file.ansible_inventory_new_yml.filename
}

