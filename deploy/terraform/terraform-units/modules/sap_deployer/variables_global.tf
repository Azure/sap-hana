/*
Description:

  Define input variables.
*/

variable "infrastructure" {}
variable "deployers" {}
variable "options" {}
variable "ssh-timeout" {}
variable "sshkey" {}
variable "user_key_vault_id" {
  description = "The user brings an existing user Key Vault"
  default     = ""
}

variable "private_key_vault_id" {
  description = "The user brings an existing private Key Vault"
  default     = ""
}
