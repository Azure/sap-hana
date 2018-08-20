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

resource "azurerm_managed_disk" "disk" {
  count                = "${length(var.storage_disk_sizes_gb)}"
  name                 = "db${var.db_num}-disk${count.index}"
  location             = "${var.az_region}"
  storage_account_type = "Premium_LRS"
  resource_group_name  = "${var.az_resource_group}"
  disk_size_gb         = "${var.storage_disk_sizes_gb[count.index]}"
  create_option        = "Empty"
}

resource "azurerm_virtual_machine_data_disk_attachment" "disk" {
  count              = "${length(var.storage_disk_sizes_gb)}"
  virtual_machine_id = "${azurerm_virtual_machine.db.id}"
  managed_disk_id    = "${element(azurerm_managed_disk.disk.*.id, count.index)}"
  lun                = "${count.index}"
  caching            = "ReadWrite"
}

# Create virtual machine
resource "azurerm_virtual_machine" "db" {
  name                          = "${var.sap_sid}-db${var.db_num}"
  location                      = "${var.az_region}"
  resource_group_name           = "${var.az_resource_group}"
  network_interface_ids         = ["${azurerm_network_interface.hdb-nic.id}"]
  vm_size                       = "${var.vm_size}"
  delete_os_disk_on_termination = "true"

  storage_os_disk {
    name              = "${var.sap_sid}-OsDisk"
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

  tags {
    environment = "Terraform SAP HANA single node deployment"
  }
}

resource null_resource "mount-disks-and-configure-hana" {
  depends_on = ["azurerm_virtual_machine.db", "azurerm_virtual_machine_data_disk_attachment.disk"]

  connection {
    user        = "${var.vm_user}"
    private_key = "${file("${var.sshkey_path_private}")}"
    timeout     = "5m"
    host        = "${local.vm_fqdn}"
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=\"False\" ansible-playbook -u ${var.vm_user} --private-key '${var.sshkey_path_private}' --extra-vars='{\"url_sapcar\": \"${var.url_sap_sapcar}\", \"url_hdbserver\": \"${var.url_sap_hdbserver}\", \"sap_sid\": \"${var.sap_sid}\", \"sap_instancenum\": \"${var.sap_instancenum}\", \"sap_hostname\": \"${local.vm_name}\", \"pwd_os_sapadm\": \"${var.pw_os_sapadm}\", \"pwd_os_sidadm\": \"${var.pw_os_sidadm}\", \"pwd_db_system\": \"${var.pw_db_system}\", \"use_hana2\": \"${var.useHana2}\" }' -i '${local.vm_fqdn},' ansible/playbook.yml"
  }
}
