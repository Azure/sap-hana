##################################################################################################################
# OUTPUT JSON
##################################################################################################################

# Generates the output JSON with IP address and disk details
resource "local_file" "output-json" {
  content = jsonencode({
    "infrastructure" = var.infrastructure,
    "jumpboxes" = {
      "windows" = [for windows-jumpbox in var.jumpboxes.windows : {
        name                 = windows-jumpbox.name,
        destroy_after_deploy = windows-jumpbox.destroy_after_deploy,
        size                 = windows-jumpbox.size,
        disk_type            = windows-jumpbox.disk_type,
        os                   = windows-jumpbox.os,
        authentication       = windows-jumpbox.authentication,
        components           = windows-jumpbox.components,
        private_ip_address   = local.ips-windows-jumpboxes[index(var.jumpboxes.windows, windows-jumpbox)]
        }
      ],
      "linux" = [for linux-jumpbox in var.jumpboxes.linux : {
        name                 = linux-jumpbox.name,
        destroy_after_deploy = linux-jumpbox.destroy_after_deploy,
        size                 = linux-jumpbox.size,
        disk_type            = linux-jumpbox.disk_type,
        os                   = linux-jumpbox.os,
        authentication       = linux-jumpbox.authentication,
        components           = linux-jumpbox.components,
        private_ip_address   = local.ips-linux-jumpboxes[index(var.jumpboxes.linux, linux-jumpbox)]
        }
      ]
    },
    "databases" = [for database in var.databases : {
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
      nodes = [for ip-dbnode-admin in local.ips-dbnodes-admin : {
        dbname       = local.dbnodes[index(local.ips-dbnodes-admin, ip-dbnode-admin)].name
        ip_admin_nic = ip-dbnode-admin,
        ip_db_nic    = local.ips-dbnodes-db[index(local.ips-dbnodes-admin, ip-dbnode-admin)],
        role         = local.dbnodes[index(local.ips-dbnodes-admin, ip-dbnode-admin)].role,
        disk_details = zipmap(range(length(flatten([for storage_type in lookup(local.sizes, "${database.size}").storage : [for disk_count in range(storage_type.count) : "${storage_type.name}-${index(range(storage_type.count), disk_count)}"] if storage_type.name != "os"]))), flatten([for storage_type in lookup(local.sizes, "${database.size}").storage : [for disk_count in range(storage_type.count) : "${storage_type.name}-${index(range(storage_type.count), disk_count)}"] if storage_type.name != "os"]))
        } if local.dbnodes[index(local.ips-dbnodes-admin, ip-dbnode-admin)].platform == database.platform
      ]
      }
    ],
    "software" = {
      "storage_account_sapbits" = {
        "name"               = var.storage-sapbits[0].name,
        "storage_access_key" = var.storage-sapbits[0].primary_access_key,
        "container_name"     = var.software.storage_account_sapbits.container_name
      }
    }
    }
  )
  filename = "${path.root}/../output.json"
}
