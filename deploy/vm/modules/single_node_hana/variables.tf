variable "ansible_playbook_path" {
  description = "Path from this module to the playbook"
  default     = "../../ansible/single_node_playbook.yml"
}

variable "az_region" {}

variable "az_resource_group" {
  description = "Which Azure resource group to deploy the HANA setup into.  i.e. <myResourceGroup>"
}

variable "bastion_username_windows" {
  description = "The username for the bastion host"
  default     = "bastion_user"
}

variable "db_num" {
  description = "which node is currently being created"
  default     = "0"
}

variable "defined_nsg" {
  default     = ""
  description = "Set this variable to the resource id of the NSG that you would like to use.  Make sure that it is in the same region as the network you assign it to."
}

variable "email_shine" {
  description = "e-mail address for SHINE user"
  default     = "shinedemo@microsoft.com"
}

variable "install_cockpit" {
  description = "Flag that determines whether to install Cockpit on the host"
  default     = false
}

variable "install_shine" {
  description = "Flag that determines whether to install SHINE on the host"
  default     = false
}

variable "install_xsa" {
  description = "Flag that determines whether to install XSA on the host"
  default     = false
}

variable "private_ip_address_hdb" {
  description = "The desired private IP address of this HANA database.  If it isn't specified, a dynamic IP will be allocated."
  default     = "10.0.0.6"
}

variable "private_ip_address_windows_bastion" {
  description = "The desired private IP address of this bastion host.  If it isn't specified, a dynamic IP will be allocated."
  default     = "10.0.0.4"
}

variable "public_ip_allocation_type" {
  description = "Defines whether the IP address is static or dynamic. Options are Static or Dynamic."
  default     = "Dynamic"
}

variable "pw_bastion_windows" {
  description = "The password for the bastion host.  Must be replaced if you plan on having a Windows bastion host"
  default     = ""
}

variable "pw_db_system" {
  description = "Password for the database user SYSTEM"
}

variable "pw_os_sapadm" {
  description = "Password for the SAP admin, which is an OS user"
}

variable "pw_os_sidadm" {
  description = "Password for this specific sidadm, which is an OS user"
}

variable "pwd_db_shine" {
  description = "Password for SHINE user"
  default     = ""
}

variable "pwd_db_tenant" {
  description = "Password for SYSTEM user (tenant DB)"
  default     = ""
}

variable "pwd_db_xsaadmin" {
  description = "Password for XSAADMIN user"
  default     = ""
}

variable "sap_instancenum" {
  description = "The sap instance number which is in range 00-99"
}

variable "sap_sid" {
  default = "PV1"
}

variable "sshkey_path_private" {
  description = "The path on the local machine to where the private key is"
}

variable "sshkey_path_public" {
  description = "The path on the local machine to where the public key is"
}

variable "storage_disk_sizes_gb" {
  description = "List disk sizes in GB for all disks this VM will need"
  default     = [512, 512, 512]
}

variable "url_cockpit" {
  description = "URL for HANA Cockpit"
  default     = ""
}

variable "url_di_core" {
  description = "URL for DI Core"
  default     = ""
}

variable "url_hana_studio_windows" {
  description = "URL for the Windows version of HANA Studio to install on the bastion host"
  default     = ""
}

variable "url_portal_services" {
  description = "URL for Portal Services"
  default     = ""
}

variable "url_sap_hdbserver" {
  type        = "string"
  description = "The URL that points to the HDB server 122.17 bits"
}

variable "url_sap_sapcar" {
  type        = "string"
  description = "The URL that points to the SAPCAR bits"
}

variable "url_sapcar_windows" {
  description = "URL for SAPCAR for Windows to run on the bastion host"
  default     = ""
}

variable "url_sapui5" {
  description = "URL for SAPUI5"
  default     = ""
}

variable "url_shine_xsa" {
  description = "URL for SHINE XSA"
  default     = ""
}

variable "url_xs_services" {
  description = "URL for XS Services"
  default     = ""
}

variable "url_xsa_runtime" {
  description = "URL for XSA runtime"
  default     = ""
}

variable "useHana2" {
  description = "If this is set to true, then, ports specifically for HANA 2.0 will be opened."
  default     = false
}

variable "vm_size" {
  default = "Standard_E8s_v3"
}

variable "vm_user" {
  description = "The username of your HANA database VM."
}

variable "azure_service_principal_id" {
  description = "Service principal Id"
  default     = ""
}

variable "azure_service_principal_pw" {
  description = "Service principal password"
  default     = ""
}

variable "windows_bastion" {
  description = "Whether or not you want a windows bastion host"
  default     = false
}
