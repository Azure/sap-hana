##################################################################################################################
# OUTPUT Files
##################################################################################################################

resource local_file "backend" {
  content = templatefile("${path.module}/backend.tmpl",
    {
      rg_name    = local.rg_name,
      sa_tfstate = local.sa_tfstate_name
  })
  filename             = "${path.cwd}/backend-config.tfvars"
  file_permission      = "0660"
  directory_permission = "0770"
}
