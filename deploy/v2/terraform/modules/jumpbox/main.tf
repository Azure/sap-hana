##################################################################################################################
# JUMPBOXES
##################################################################################################################

# NETWORK SECURITY RULES =========================================================================================

# Creates Windows jumpbox RDP network security rule
resource "azurerm_network_security_rule" "nsr-rdp" {
  count                       = var.infrastructure.vnets.management.subnet_mgmt.nsg.is_existing ? 0 : 1
  name                        = "rdp"
  resource_group_name         = var.nsg-mgmt[0].resource_group_name
  network_security_group_name = var.nsg-mgmt[0].name
  priority                    = 101
  direction                   = "Inbound"
  access                      = "allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = 3389
  source_address_prefixes     = var.infrastructure.vnets.management.subnet_mgmt.nsg.allowed_ips
  destination_address_prefix  = var.infrastructure.vnets.management.subnet_mgmt.prefix
}

# Creates Windows jumpbox WinRM network security rule
resource "azurerm_network_security_rule" "nsr-winrm" {
  count                       = var.infrastructure.vnets.management.subnet_mgmt.nsg.is_existing ? 0 : 1
  name                        = "winrm"
  resource_group_name         = var.nsg-mgmt[0].resource_group_name
  network_security_group_name = var.nsg-mgmt[0].name
  priority                    = 102
  direction                   = "Inbound"
  access                      = "allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = [5985, 5986]
  source_address_prefixes     = var.infrastructure.vnets.management.subnet_mgmt.nsg.allowed_ips
  destination_address_prefix  = var.infrastructure.vnets.management.subnet_mgmt.prefix
}

# Creates Linux jumpbox and RTI box SSH network security rule
resource "azurerm_network_security_rule" "nsr-ssh" {
  count                       = var.infrastructure.vnets.management.subnet_mgmt.nsg.is_existing ? 0 : 1
  name                        = "ssh"
  resource_group_name         = var.nsg-mgmt[0].resource_group_name
  network_security_group_name = var.nsg-mgmt[0].name
  priority                    = 103
  direction                   = "Inbound"
  access                      = "allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = 22
  source_address_prefixes     = var.infrastructure.vnets.management.subnet_mgmt.nsg.allowed_ips
  destination_address_prefix  = var.infrastructure.vnets.management.subnet_mgmt.prefix
}

# NICS ============================================================================================================

# Creates the public IP addresses for Windows VMs
resource "azurerm_public_ip" "public-ip-windows" {
  count               = length(var.jumpboxes.windows)
  name                = "${var.jumpboxes.windows[count.index].name}-public-ip"
  location            = var.resource-group[0].location
  resource_group_name = var.resource-group[0].name
  allocation_method   = "Static"
}

# Creates the NIC and IP address for Windows VMs
resource "azurerm_network_interface" "nic-windows" {
  count               = length(var.jumpboxes.windows)
  name                = "${var.jumpboxes.windows[count.index].name}-nic1"
  location            = var.resource-group[0].location
  resource_group_name = var.resource-group[0].name

  ip_configuration {
    name                          = "${var.jumpboxes.windows[count.index].name}-nic1-ip"
    subnet_id                     = var.subnet-mgmt[0].id
    private_ip_address            = var.infrastructure.vnets.management.subnet_mgmt.is_existing ? var.jumpboxes.windows[count.index].private_ip_address : lookup(var.jumpboxes.windows[count.index], "private_ip_address", false) != false ? var.jumpboxes.windows[count.index].private_ip_address : cidrhost(var.infrastructure.vnets.management.subnet_mgmt.prefix, (count.index + 4))
    private_ip_address_allocation = "static"
    public_ip_address_id          = azurerm_public_ip.public-ip-windows[count.index].id
  }
}

/*-----------------------------------------------------------------------------8
TODO 20200414-MKD: Move Resource block

  RESOURCE BLOCK: resource "azurerm_public_ip" "public-ip-linux"

  MOVE CODE INTO: vm-jump.tf
+--------------------------------------4--------------------------------------*/
/*-----------------------------------------------------------------------------8
TODO 20200414-MKD: Make RTI independent resource deployment

  PROBLEM:  resource block for pip, nic, nsg, and vm can't be removed since they
            are also used to create other jumpboxes that are not rti.
            The way this can be done is:

              make rti not one of the jumpboxes
              copy code that's shared between jumpboxes and rti
              remove code that is only used by rti to rti.tf

  RESOURCE BLOCK: resource "azurerm_public_ip" "public-ip-linux"

  COPY CODE INTO: vm-rti.tf

  Change Object ID
    FROM: resource "azurerm_public_ip" "public-ip-linux"
    TO:   resource "azurerm_public_ip" "rti"

  Decouple from var.jumpboxes.linux and specify an RTI count parameter with a 
  default of 1

  Fix Naming convention Let's discuss and document in the Naming Convention Doc
+--------------------------------------4--------------------------------------*/
# Creates the public IP addresses for Linux VMs
resource "azurerm_public_ip" "public-ip-linux" {
  count               = length(var.jumpboxes.linux)
  name                = "${var.jumpboxes.linux[count.index].name}-public-ip"
  location            = var.resource-group[0].location
  resource_group_name = var.resource-group[0].name
  allocation_method   = "Static"
}

/*-----------------------------------------------------------------------------8
TODO 20200414-MKD: Move Resource block

  RESOURCE BLOCK: resource "azurerm_network_interface" "nic-linux"

  MOVE CODE INTO: vm-jump.tf
+--------------------------------------4--------------------------------------*/
/*-----------------------------------------------------------------------------8
TODO 20200414-MKD: Make RTI independent resource deployment

  PROBLEM:  resource block for pip, nic, nsg, and vm can't be removed since they
            are also used to create other jumpboxes that are not rti.
            The way this can be done is:

              make rti not one of the jumpboxes
              copy code that's shared between jumpboxes and rti
              remove code that is only used by rti to rti.tf

  RESOURCE BLOCK: resource "azurerm_network_interface" "nic-linux"

  COPY CODE INTO: vm-rti.tf

  Change Object ID
    FROM: resource "azurerm_network_interface" "nic-linux"
    TO:   resource "azurerm_network_interface" "rti"

  Decouple from var.jumpboxes.linux and specify an RTI count parameter with a 
  default of 1

  Fix Naming convention Let's discuss and document in the Naming Convention Doc

  Change ip_configuration.name to a static value. ex. ipconfig1
+--------------------------------------4--------------------------------------*/
# Creates the NIC and IP address for Linux VMs
resource "azurerm_network_interface" "nic-linux" {
  count               = length(var.jumpboxes.linux)
  name                = "${var.jumpboxes.linux[count.index].name}-nic1"
  location            = var.resource-group[0].location
  resource_group_name = var.resource-group[0].name

  ip_configuration {
    name                          = "${var.jumpboxes.linux[count.index].name}-nic1-ip"
    subnet_id                     = var.subnet-mgmt[0].id
    private_ip_address            = var.infrastructure.vnets.management.subnet_mgmt.is_existing ? var.jumpboxes.linux[count.index].private_ip_address : lookup(var.jumpboxes.linux[count.index], "private_ip_address", false) != false ? var.jumpboxes.linux[count.index].private_ip_address : cidrhost(var.infrastructure.vnets.management.subnet_mgmt.prefix, (count.index + 4 + length(var.jumpboxes.windows)))
    private_ip_address_allocation = "static"
    public_ip_address_id          = azurerm_public_ip.public-ip-linux[count.index].id
  }
}

# Manages the association between NIC and NSG
resource "azurerm_network_interface_security_group_association" "nic-windows-nsg" {
  count                     = length(var.jumpboxes.windows)
  network_interface_id      = azurerm_network_interface.nic-windows[count.index].id
  network_security_group_id = var.nsg-mgmt[0].id
}

/*-----------------------------------------------------------------------------8
TODO 20200414-MKD: Move Resource block

  RESOURCE BLOCK: resource "azurerm_network_interface_security_group_association" "nic-linux-nsg"

  MOVE CODE INTO: vm-jump.tf
+--------------------------------------4--------------------------------------*/
/*-----------------------------------------------------------------------------8
TODO 20200415-MKD: Make RTI independent resource deployment

  PROBLEM:  resource block for pip, nic, nsg, and vm can't be removed since they
            are also used to create other jumpboxes that are not rti.
            The way this can be done is:

              make rti not one of the jumpboxes
              copy code that's shared between jumpboxes and rti
              remove code that is only used by rti to rti.tf

  RESOURCE BLOCK: resource "azurerm_network_interface_security_group_association" "nic-linux-nsg"

  COPY CODE INTO: vm-rti.tf

  Change Object ID
    FROM: resource "azurerm_network_interface_security_group_association" "nic-linux-nsg"
    TO:   resource "azurerm_network_interface_security_group_association" "rti"

  Decouple from var.jumpboxes.linux and specify an RTI count parameter with a 
  default of 1
+--------------------------------------4--------------------------------------*/
resource "azurerm_network_interface_security_group_association" "nic-linux-nsg" {
  count                     = length(var.jumpboxes.linux)
  network_interface_id      = azurerm_network_interface.nic-linux[count.index].id
  network_security_group_id = var.nsg-mgmt[0].id
}

# VIRTUAL MACHINES ================================================================================================

/*-----------------------------------------------------------------------------8
TODO 20200414-MKD: Move Resource block

  RESOURCE BLOCK: resource "azurerm_linux_virtual_machine" "vm-linux"

  MOVE CODE INTO: vm-jump.tf
+--------------------------------------4--------------------------------------*/
/*-----------------------------------------------------------------------------8
TODO 20200415-MKD: Make RTI independent resource deployment

  PROBLEM:  resource block for pip, nic, nsg, and vm can't be removed since they
            are also used to create other jumpboxes that are not rti.
            The way this can be done is:

              make rti not one of the jumpboxes
              copy code that's shared between jumpboxes and rti
              remove code that is only used by rti to rti.tf

  RESOURCE BLOCK: resource "azurerm_linux_virtual_machine" "vm-linux"

  COPY CODE INTO: vm-rti.tf

  Change Object ID
    FROM: resource "azurerm_linux_virtual_machine" "vm-linux"
    TO:   resource "azurerm_linux_virtual_machine" "rti"

  Decouple from var.jumpboxes.linux and specify an RTI count parameter with a 
  default of 1

  Fix Naming convention Let's discuss and document in the Naming Convention Doc
+--------------------------------------4--------------------------------------*/
# Manages Linux Virtual Machine for Linux jumpboxes
resource "azurerm_linux_virtual_machine" "vm-linux" {
  count                           = length(var.jumpboxes.linux)
  name                            = var.jumpboxes.linux[count.index].name
  location                        = var.resource-group[0].location
  resource_group_name             = var.resource-group[0].name
  network_interface_ids           = [azurerm_network_interface.nic-linux[count.index].id]
  size                            = var.jumpboxes.linux[count.index].size
  computer_name                   = var.jumpboxes.linux[count.index].name
  admin_username                  = var.jumpboxes.linux[count.index].authentication.username
  admin_password                  = lookup(var.jumpboxes.linux[count.index].authentication, "password", null)
  disable_password_authentication = var.jumpboxes.linux[count.index].authentication.type != "password" ? true : false

  os_disk {
    name                 = "${var.jumpboxes.linux[count.index].name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = var.jumpboxes.linux[count.index].disk_type
  }

  source_image_reference {
    publisher = var.jumpboxes.linux[count.index].os.publisher
    offer     = var.jumpboxes.linux[count.index].os.offer
    sku       = var.jumpboxes.linux[count.index].os.sku
    version   = "latest"
  }

  admin_ssh_key {
    username   = var.jumpboxes.linux[count.index].authentication.username
    public_key = file(var.sshkey.path_to_public_key)

  }

  boot_diagnostics {
    storage_account_uri = var.storage-bootdiag.primary_blob_endpoint
  }

  tags = {
    JumpboxName = var.jumpboxes.linux[count.index].destroy_after_deploy ? "RTI" : "LINUX-JUMPBOX"
  }

  connection {
    type        = "ssh"
    host        = azurerm_public_ip.public-ip-linux[count.index].ip_address
    user        = var.jumpboxes.linux[count.index].authentication.username
    private_key = var.jumpboxes.linux[count.index].authentication.type == "key" ? file(var.sshkey.path_to_private_key) : null
    password    = lookup(var.jumpboxes.linux[count.index].authentication, "password", null)
    timeout     = var.ssh-timeout
  }

  # Copies ssh keypair over to jumpboxes and sets permission
  provisioner "file" {
    source      = lookup(var.sshkey, "path_to_public_key", null)
    destination = "/home/${var.jumpboxes.linux[count.index].authentication.username}/.ssh/id_rsa.pub"
  }

  provisioner "file" {
    source      = lookup(var.sshkey, "path_to_private_key", null)
    destination = "/home/${var.jumpboxes.linux[count.index].authentication.username}/.ssh/id_rsa"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 644 /home/${var.jumpboxes.linux[count.index].authentication.username}/.ssh/id_rsa.pub",
      "chmod 600 /home/${var.jumpboxes.linux[count.index].authentication.username}/.ssh/id_rsa",
    ]
  }
}

# Manages Windows Virtual Machine for Windows jumpboxes
resource "azurerm_windows_virtual_machine" "vm-windows" {
  count                 = length(var.jumpboxes.windows)
  name                  = var.jumpboxes.windows[count.index].name
  location              = var.resource-group[0].location
  resource_group_name   = var.resource-group[0].name
  network_interface_ids = [azurerm_network_interface.nic-windows[count.index].id]
  size                  = var.jumpboxes.windows[count.index].size
  computer_name         = var.jumpboxes.windows[count.index].name
  admin_username        = var.jumpboxes.windows[count.index].authentication.username
  admin_password        = var.jumpboxes.windows[count.index].authentication.password
  custom_data           = base64encode("Param($ComputerName = \"${var.jumpboxes.windows[count.index].name}\") ${file("${path.module}/winrm_files/winrm.ps1")}")
  provision_vm_agent    = true

  os_disk {
    name                 = "${var.jumpboxes.windows[count.index].name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = var.jumpboxes.windows[count.index].disk_type
  }

  source_image_reference {
    publisher = var.jumpboxes.windows[count.index].os.publisher
    offer     = var.jumpboxes.windows[count.index].os.offer
    sku       = var.jumpboxes.windows[count.index].os.sku
    version   = "latest"
  }

  secret {
    certificate {
      store = "My"
      url   = azurerm_key_vault_certificate.key-vault-cert[count.index].secret_id
    }
    key_vault_id = azurerm_key_vault.key-vault.id
  }

  winrm_listener {
    protocol        = "Https"
    certificate_url = azurerm_key_vault_certificate.key-vault-cert[count.index].secret_id
  }


  # Auto-Login's required to configure WinRM
  additional_unattend_content {
    setting = "AutoLogon"
    content = "<AutoLogon><Password><Value>${var.jumpboxes.windows[count.index].authentication.password}</Value></Password><Enabled>true</Enabled><LogonCount>2</LogonCount><Username>${var.jumpboxes.windows[count.index].authentication.username}</Username></AutoLogon>"
  }

  # Unattended config is to enable basic auth in WinRM, required for the provisioner stage
  additional_unattend_content {
    setting = "FirstLogonCommands"
    content = file("${path.module}/winrm_files/FirstLogonCommands.xml")
  }

  boot_diagnostics {
    storage_account_uri = var.storage-bootdiag.primary_blob_endpoint
  }

  tags = {
    JumpboxName = var.jumpboxes.windows[count.index].destroy_after_deploy ? "RTI" : "WINDOWS-JUMPBOX"
  }
}

/*-----------------------------------------------------------------------------8
TODO 20200414-MKD: Make RTI independent resource deployment

  PROBLEM:  resource block for pip, nic, nsg, and vm can't be removed since they
            are also used to create other jumpboxes that are not rti.
            The way this can be done is:

              make rti not one of the jumpboxes
              copy code that's shared between jumpboxes and rti
              remove code that is only used by rti to rti.tf

  RESOURCE BLOCK: resource "null_resource" "prepare-rti"

  MOVE CODE INTO: vm-rti.tf

  Fix depends_on
+--------------------------------------4--------------------------------------*/
# Prepare RTI:
#   1. Copy folder ansible_config_files over to RTI
#   2. Install Git/Ansible and clone GitHub repo on RTI
resource "null_resource" "prepare-rti" {
  depends_on = [azurerm_linux_virtual_machine.vm-linux]
  connection {
    type        = "ssh"
    host        = local.rti-info[0].public_ip_address
    user        = local.rti-info[0].authentication.username
    private_key = local.rti-info[0].authentication.type == "key" ? file(var.sshkey.path_to_private_key) : null
    password    = lookup(local.rti-info[0].authentication, "password", null)
    timeout     = var.ssh-timeout
  }

  # Copies output.json and inventory file for ansbile on RTI.
  provisioner "file" {
    source      = "${path.root}/../ansible_config_files/"
    destination = "/home/${local.rti-info[0].authentication.username}"
  }

  # Copies Clustering Service Principal for ansbile on RTI.
  provisioner "file" {
    # Note: We provide a default empty clustering auth script content so this provisioner succeeds.
    # Later in the execution, the script is sourced, but will have no impact if it has been defaulted
    content     = fileexists("${path.cwd}/set-clustering-auth-${local.hana-sid}.sh") ? file("${path.cwd}/set-clustering-auth-${local.hana-sid}.sh") : "# default empty clustering auth script"
    destination = "/home/${local.rti-info[0].authentication.username}/export-clustering-sp-details.sh"
  }

  # Installs Git, Ansible and clones repository on RTI
  provisioner "remote-exec" {
    inline = [
      # Installs Git
      "sudo apt update",
      "sudo apt-get install git=1:2.7.4-0ubuntu1.6",
      # Install pip3
      "sudo apt -y install python3-pip",
      # Installs Ansible
      "sudo -H pip3 install \"ansible>=2.8,<2.9\"",
      # Install pywinrm
      "sudo -H pip3 install \"pywinrm>=0.3.0\"",
      # Clones project repository
      "git clone https://github.com/Azure/sap-hana.git"
    ]
  }
}
