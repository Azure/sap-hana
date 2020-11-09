##################################################################################################################
# OUTPUT Files
##################################################################################################################

# Generates the output JSON with IP address and disk details
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
  content = templatefile("${path.module}/ansible_inventory.tmpl", {
    iscsi             = var.infrastructure_w_defaults.iscsi,
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
  filename             = "${path.cwd}/ansible_config_files/hosts"
  file_permission      = "0660"
  directory_permission = "0770"
}

# Generates the Ansible Inventory file
resource "local_file" "ansible_inventory_yml" {
  content = templatefile("${path.module}/ansible_inventory.yml.tmpl", {
    iscsi             = var.infrastructure_w_defaults.iscsi,
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
