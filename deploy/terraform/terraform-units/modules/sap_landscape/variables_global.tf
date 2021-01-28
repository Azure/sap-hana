variable "infrastructure" {}
variable "options" {}
variable "sshkey" {}
variable "key_vault" {
  description = "The user brings existing Azure Key Vaults"
  default     = ""
}
