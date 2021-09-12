##################################################################################################################
# OUTPUT Files
##################################################################################################################

resource "local_file" "backend" {
  content = templatefile(format("%s/backend.tmpl", path.module),
    {
      rg_name    = local.rg_name,
      sa_tfstate = local.sa_tfstate_name
  })
  filename = format("%s/backend-config.tfvars", path.cwd)

  file_permission      = "0660"
  directory_permission = "0770"
}


