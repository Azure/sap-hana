variable "infrastructure" {}
variable "options" {}
variable "ssh-timeout" {}
variable "sshkey" {}
variable "key_vault" {
  description = "The user brings existing Azure Key Vaults"
  default     = ""
}
