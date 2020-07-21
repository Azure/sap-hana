/*
Description:

  Define 1..n Deployer(s).
*/

// Public IP addresse and nic for Deployer
resource "azurerm_public_ip" "deployer" {
  count               = length(local.deployers)
  name                = format("%s%02d-pip-%s", local.deployers[count.index].name, count.index, local.postfix)
  location            = azurerm_resource_group.deployer.location
  resource_group_name = azurerm_resource_group.deployer.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "deployer" {
  count               = length(local.deployers)
  name                = format("%s%02d-nic-%s", local.deployers[count.index].name, count.index, local.postfix)
  location            = azurerm_resource_group.deployer.location
  resource_group_name = azurerm_resource_group.deployer.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = local.sub_mgmt_deployed.id
    private_ip_address            = local.deployers[count.index].private_ip_address
    private_ip_address_allocation = "static"
    public_ip_address_id          = azurerm_public_ip.deployer[count.index].id
  }
}

// Linux Virtual Machine for Deployer
resource "azurerm_linux_virtual_machine" "deployer" {
  count                           = length(local.deployers)
  name                            = format("%s%02d-vm-%s", local.deployers[count.index].name, count.index, local.postfix)
  computer_name                   = format("%s%02d-vm-%s", local.deployers[count.index].name, count.index, local.postfix)
  location                        = azurerm_resource_group.deployer.location
  resource_group_name             = azurerm_resource_group.deployer.name
  network_interface_ids           = [azurerm_network_interface.deployer[count.index].id]
  size                            = local.deployers[count.index].size
  admin_username                  = local.deployers[count.index].authentication.username
  admin_password                  = lookup(local.deployers[count.index].authentication, "password", null)
  disable_password_authentication = local.deployers[count.index].authentication.type != "password" ? true : false

  os_disk {
    name                 = format("%s%02d-OsDisk-%s", local.deployers[count.index].name, count.index, local.postfix)
    caching              = "ReadWrite"
    storage_account_type = local.deployers[count.index].disk_type
  }

  source_image_id = local.deployers[count.index].os.source_image_id != "" ? local.deployers[count.index].os.source_image_id : null

  dynamic "source_image_reference" {
    for_each = range(local.deployers[count.index].os.source_image_id == "" ? 1 : 0)
    content {
      publisher = local.deployers[count.index].os.publisher
      offer     = local.deployers[count.index].os.offer
      sku       = local.deployers[count.index].os.sku
      version   = local.deployers[count.index].os.version
    }
  }

  admin_ssh_key {
    username   = local.deployers[count.index].authentication.username
    public_key = file(var.sshkey.path_to_public_key)
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.deployer.primary_blob_endpoint
  }

  tags = {
    JumpboxName = "Deployer"
  }

  connection {
    type        = "ssh"
    host        = azurerm_public_ip.deployer[count.index].ip_address
    user        = local.deployers[count.index].authentication.username
    private_key = local.deployers[count.index].authentication.type == "key" ? file(var.sshkey.path_to_private_key) : null
    password    = lookup(local.deployers[count.index].authentication, "password", null)
    timeout     = var.ssh-timeout
  }

  // Copy ssh keypair over to Deployer and sets permission
  provisioner "file" {
    source      = lookup(var.sshkey, "path_to_public_key", null)
    destination = "/home/${local.deployers[count.index].authentication.username}/.ssh/id_rsa.pub"
  }

  provisioner "file" {
    source      = lookup(var.sshkey, "path_to_private_key", null)
    destination = "/home/${local.deployers[count.index].authentication.username}/.ssh/id_rsa"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 644 /home/${local.deployers[count.index].authentication.username}/.ssh/id_rsa.pub",
      "chmod 600 /home/${local.deployers[count.index].authentication.username}/.ssh/id_rsa",
    ]
  }
}

// Prepare deployer with pre-installed softwares
resource "null_resource" "prepare-deployer" {
  depends_on = [azurerm_linux_virtual_machine.deployer]
  count      = length(local.deployers)

  connection {
    type        = "ssh"
    host        = azurerm_public_ip.deployer[count.index].ip_address
    user        = local.deployers[count.index].authentication.username
    private_key = local.deployers[count.index].authentication.type == "key" ? file(var.sshkey.path_to_private_key) : null
    password    = lookup(local.deployers[count.index].authentication, "password", null)
    timeout     = var.ssh-timeout
  }

  provisioner "remote-exec" {
    inline = local.deployers[count.index].os.source_image_id != "" ? [] : [
      // Install terraform
      "sudo apt-get install unzip",
      "wget https://releases.hashicorp.com/terraform/0.12.28/terraform_0.12.28_linux_amd64.zip",
      "unzip terraform_0.12.28_linux_amd64.zip",
      "sudo mv terraform /usr/local/bin/terraform",
      // Install az cli
      "curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash",
      // Installs Git
      "sudo apt update",
      "sudo apt-get install git=1:2.7.4-0ubuntu1.6",
      // Install pip3
      "sudo apt -y install python3-pip",
      // Installs Ansible
      "sudo -H pip3 install \"ansible>=2.8,<2.9\"",
      // Install pywinrm
      "sudo -H pip3 install \"pywinrm>=0.3.0\"",
      // Clones project repository
      "git clone https://github.com/Azure/sap-hana.git"
    ]
  }
}
