# Configure the Microsoft Azure Provider
provider "azurerm" {} #TODO(pabowers): add ability to specify subscription

variable "az_region" {}

variable "vm_user" {
  description = "The username of your HANA db vm."
}

variable "az_domain_name" {
  description = "A name that is used to access your HANA vm"
}

variable "sshkey_path_private" {
  description = "The path on the local machine to where the private key is"
}

variable "sshkey_path_public" {
  description = "The path on the local machine to where the public key is"
}

variable "az_resource_group" {
  description = "Which azure resource group to deploy the HANA setup into.  i.e. <myResourceGroup>"
}

variable "sap_sid" {
  default = "PV1"
}

variable "sap_instancenum" {
  description = "The sap instance number which is in range 00-99"
}

variable "db_num" {
  description = "which node is currently being created"
}

variable "vm_size" {
  default = "Standard_E8s_v3"
}

variable "url_sap_sapcar" {
  type        = "string"
  description = "The url that points to the SAPCAR bits"
}

variable "url_sap_hostagent" {
  type        = "string"
  description = "The url that points to the sap host agent 36 bits"
}

variable "url_sap_hdbserver" {
  type        = "string"
  description = "The url that points to the HDB server 122.17 bits"
}

variable "pw_os_sapadm" {
  description = "Password for the SAP admin, which is an OS user"
}

variable "pw_os_sidadm" {
  description = "Password for this specific sidadm, which is an OS user"
}

variable "pw_db_system" {
  description = "Password for the database user SYSTEM"
}

locals {
  vm_fqdn                 = "${azurerm_public_ip.hdb-pip.fqdn}"
  vm_name                 = "${var.sap_sid}-db${var.db_num}"
  disksize_hana_data_gb   = 512
  disksize_hana_log_gb    = 512
  disksize_hana_shared_gb = 512
}

data "http" "local_ip" {
  url = "http://v4.ifconfig.co"
}

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "hana-resource-group" {
  name     = "${var.az_resource_group}"
  location = "${var.az_region}"

  tags {
    environment = "Terraform SAP HANA single node deployment"
  }
}

# Create virtual network
resource "azurerm_virtual_network" "hana-vnet" {
  name                = "${var.sap_sid}-vnet"
  address_space       = ["10.0.0.0/21"]
  location            = "${var.az_region}"
  resource_group_name = "${azurerm_resource_group.hana-resource-group.name}"

  tags {
    environment = "Terraform SAP HANA single node deployment"
  }
}

# Create subnet
resource "azurerm_subnet" "hana-subnet" {
  name                      = "${var.sap_sid}-subnet"
  resource_group_name       = "${azurerm_resource_group.hana-resource-group.name}"
  virtual_network_name      = "${azurerm_virtual_network.hana-vnet.name}"
  network_security_group_id = "${azurerm_network_security_group.hdb-nsg.id}"
  address_prefix            = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "hdb-pip" {
  name                         = "${var.sap_sid}-db${var.db_num}-pip"
  location                     = "${var.az_region}"
  resource_group_name          = "${azurerm_resource_group.hana-resource-group.name}"
  public_ip_address_allocation = "dynamic"
  idle_timeout_in_minutes      = 30
  domain_name_label            = "${var.az_domain_name}"

  tags {
    environment = "Terraform SAP HANA single node deployment"
  }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "hdb-nsg" {
  name                = "${var.sap_sid}-nsg"
  location            = "${var.az_region}"
  resource_group_name = "${azurerm_resource_group.hana-resource-group.name}"

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "local-ip-allow-vnet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "${chomp(data.http.local_ip.body)}"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "open-hana-db-ports"
    priority                   = 1020
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3${var.sap_instancenum}00-3${var.sap_instancenum}99"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1030
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80${var.sap_instancenum}"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTPS"
    priority                   = 1040
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "43${var.sap_instancenum}"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags {
    environment = "Terraform SAP HANA single node deployment"
  }
}

# Create network interface
resource "azurerm_network_interface" "hdb-nic" {
  name                      = "${var.sap_sid}-db${var.db_num}-nic"
  location                  = "${var.az_region}"
  resource_group_name       = "${azurerm_resource_group.hana-resource-group.name}"
  network_security_group_id = "${azurerm_network_security_group.hdb-nsg.id}"

  ip_configuration {
    name      = "myNicConfiguration"
    subnet_id = "${azurerm_subnet.hana-subnet.id}"

    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.hdb-pip.id}"
  }

  tags {
    environment = "Terraform SAP HANA single node deployment"
  }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = "${azurerm_resource_group.hana-resource-group.name}"
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
  name                     = "diag${random_id.randomId.hex}"
  resource_group_name      = "${azurerm_resource_group.hana-resource-group.name}"
  location                 = "${var.az_region}"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags {
    environment = "Terraform SAP HANA single node deployment"
  }
}

# Create virtual machine
resource "azurerm_virtual_machine" "db" {
  name                  = "${var.sap_sid}-db${var.db_num}"
  location              = "${var.az_region}"
  resource_group_name   = "${azurerm_resource_group.hana-resource-group.name}"
  network_interface_ids = ["${azurerm_network_interface.hdb-nic.id}"]
  vm_size               = "${var.vm_size}"

  storage_os_disk {
    name              = "myOsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "SUSE"
    offer     = "SLES-SAP"
    sku       = "12-SP3"
    version   = "latest"
  }

  storage_data_disk {
    name              = "hana-data-disk"
    managed_disk_type = "Premium_LRS"
    create_option     = "Empty"
    disk_size_gb      = "${local.disksize_hana_data_gb}"
    lun               = 0
  }

  storage_data_disk {
    name              = "hana-log-disk"
    managed_disk_type = "Premium_LRS"
    create_option     = "Empty"
    disk_size_gb      = "${local.disksize_hana_log_gb}"
    lun               = 1
  }

  storage_data_disk {
    name              = "hana-shared-disk"
    managed_disk_type = "Premium_LRS"
    create_option     = "Empty"
    disk_size_gb      = "${local.disksize_hana_shared_gb}"
    lun               = 2
  }

  os_profile {
    computer_name  = "${local.vm_name}"
    admin_username = "${var.vm_user}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.vm_user}/.ssh/authorized_keys"
      key_data = "${file("${var.sshkey_path_public}")}"
    }
  }

  boot_diagnostics {
    enabled = "true"

    storage_uri = "${azurerm_storage_account.mystorageaccount.primary_blob_endpoint}"
  }

  connection {
    user        = "${var.vm_user}"
    private_key = "${file("${var.sshkey_path_private}")}"
    timeout     = "20m"
    host        = "${local.vm_fqdn}"
  }

  provisioner "file" {
    source      = "provision_hardware.sh"
    destination = "/tmp/provision_hardware.sh"
  }

  provisioner "file" {
    source      = "sid_config_template.txt"
    destination = "/tmp/sid_config_template.txt"
  }

  provisioner "file" {
    source      = "sid_passwords_template.txt"
    destination = "/tmp/sid_passwords_template.txt"
  }

  provisioner "file" {
    source      = "install_HANA.sh"
    destination = "/tmp/install_HANA.sh"
  }

  provisioner "file" {
    source      = "machine_setup_tests.sh"
    destination = "/tmp/machine_setup_tests.sh"
  }

  provisioner "file" {
    source      = "shunit2"
    destination = "/tmp/shunit2"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/provision_hardware.sh",
      "sudo /tmp/provision_hardware.sh ${var.sap_sid}",
      "chmod +x /tmp/install_HANA.sh",
      "sudo /tmp/install_HANA.sh \"${var.url_sap_sapcar}\" \"${var.url_sap_hostagent}\" \"${var.url_sap_hdbserver}\" \"${var.sap_sid}\" \"${local.vm_name}\" \"${var.sap_instancenum}\" \"${var.pw_os_sapadm}\" \"${var.pw_os_sidadm}\" \"${var.pw_db_system}\"",
    ]
  }

  tags {
    environment = "Terraform SAP HANA single node deployment"
  }
}

// -------------------------------------------------------------------------
// Print out login information
// -------------------------------------------------------------------------
output "ip" {
  value = "Created vm ${azurerm_virtual_machine.db.id}"
  value = "Connect using ${var.vm_user}@${local.vm_fqdn}"
}
