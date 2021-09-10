/*
Description:

  Define input variables.
*/

variable "infrastructure" {}
variable "deployers" {}
variable "options" {}
variable "ssh-timeout" {}
variable "authentication" {}
variable "key_vault" {
  description = "The user brings existing Azure Key Vaults"
  default     = ""
}


variable "arm_client_id" {
  default = "70000000-0000-0000-0000-000000000000"
}

