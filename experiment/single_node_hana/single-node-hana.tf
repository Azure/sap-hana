# Configure the Microsoft Azure Provider
provider "azurerm" {} #TODO(pabowers): add ability to specify subscription

locals {
  vm_fqdn                 = "${azurerm_public_ip.hana-db-pip.fqdn}"
  vm_name                 = "${var.sap_sid}-db${var.db_num}"
  disksize_gb_hana_data   = 512
  disksize_gb_hana_log    = 512
  disksize_gb_hana_shared = 512
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
resource "azurerm_public_ip" "hana-db-pip" {
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

resource "azurerm_network_interface" "db-nic" {
  name                      = "${var.sap_sid}-db${var.db_num}-nic"
  location                  = "${var.az_region}"
  resource_group_name       = "${azurerm_resource_group.hana-resource-group.name}"
  network_security_group_id = "${azurerm_network_security_group.hdb-nsg.id}"

  ip_configuration {
    name      = "myNicConfiguration"
    subnet_id = "${azurerm_subnet.hana-subnet.id}"

    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.hana-db-pip.id}"
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
  network_interface_ids = ["${azurerm_network_interface.db-nic.id}"]
  vm_size               = "${var.vm_size}"

  storage_os_disk {
    name              = "myOsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "SUSE"
    offer     = "SLES-SAP"
    sku       = "12-SP3"
    version   = "latest"
  }

  storage_data_disk {
    name              = "hana-data-disk"
    managed_disk_type = "Standard_LRS"
    create_option     = "Empty"
    disk_size_gb      = "${local.disksize_gb_hana_data}"
    lun               = 0
  }

  storage_data_disk {
    name              = "hana-log-disk"
    managed_disk_type = "Standard_LRS"
    create_option     = "Empty"
    disk_size_gb      = "${local.disksize_gb_hana_log}"
    lun               = 1
  }

  storage_data_disk {
    name              = "hana-shared-disk"
    managed_disk_type = "Standard_LRS"
    create_option     = "Empty"
    disk_size_gb      = "${local.disksize_gb_hana_shared}"
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
