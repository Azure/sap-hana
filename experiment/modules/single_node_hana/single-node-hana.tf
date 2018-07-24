# Configure the Microsoft Azure Provider
provider "azurerm" {} #TODO(pabowers): add ability to specify subscription

# Create public IPs
resource "azurerm_public_ip" "hdb-pip" {
  name                         = "${var.sap_sid}-db${var.db_num}-pip"
  location                     = "${var.az_region}"
  resource_group_name          = "${var.az_resource_group}"
  public_ip_address_allocation = "dynamic"
  idle_timeout_in_minutes      = 30
  domain_name_label            = "${var.az_domain_name}"

  tags {
    environment = "Terraform SAP HANA single node deployment"
  }
}

# Create network interface
resource "azurerm_network_interface" "hdb-nic" {
  name                      = "${var.sap_sid}-db${var.db_num}-nic"
  location                  = "${var.az_region}"
  resource_group_name       = "${var.az_resource_group}"
  network_security_group_id = "${var.nsg_id}"

  ip_configuration {
    name      = "myNicConfiguration"
    subnet_id = "${var.hana_subnet_id}"

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
    resource_group = "${var.az_resource_group}"
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
  name                     = "diag${random_id.randomId.hex}"
  resource_group_name      = "${var.az_resource_group}"
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
  resource_group_name   = "${var.az_resource_group}"
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
    source      = "${path.module}/provision_hardware.sh"
    destination = "/tmp/provision_hardware.sh"
  }

  provisioner "file" {
    source      = "${path.module}/sid_config_template.txt"
    destination = "/tmp/sid_config_template.txt"
  }

  provisioner "file" {
    source      = "${path.module}/sid_passwords_template.txt"
    destination = "/tmp/sid_passwords_template.txt"
  }

  provisioner "file" {
    source      = "${path.module}/shunit2"
    destination = "/tmp/shunit2"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/provision_hardware.sh",
      "sudo /tmp/provision_hardware.sh ${var.sap_sid}",
    ]
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.vm_user} --private-key '${var.sshkey_path_private}' -i '${local.vm_fqdn},' ansible/playbook.yml"
  }

  tags {
    environment = "Terraform SAP HANA single node deployment"
  }
}
