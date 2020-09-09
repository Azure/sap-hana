/*
Description:

  The deployer will be used to run Terraform and Anisbe tasks to create the SAP environments

  Define 0..n Deployer(s).
*/

// Public IP addresse and nic for Deployer
resource "azurerm_public_ip" "deployer" {
  count               = length(local.deployers)
  name                = format("%s-%s%02d-pip", local.prefix, local.deployers[count.index].name, count.index)
  location            = azurerm_resource_group.deployer[0].location
  resource_group_name = azurerm_resource_group.deployer[0].name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "deployer" {
  count               = length(local.deployers)
  name                = format("%s-%s%02d-nic", local.prefix, local.deployers[count.index].name, count.index)
  location            = azurerm_resource_group.deployer[0].location
  resource_group_name = azurerm_resource_group.deployer[0].name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = local.sub_mgmt_deployed.id
    private_ip_address            = local.deployers[count.index].private_ip_address
    private_ip_address_allocation = "static"
    public_ip_address_id          = azurerm_public_ip.deployer[count.index].id
  }
}

// User defined identity for all Deployer, assign contributor to the current subscription
resource "azurerm_user_assigned_identity" "deployer" {
  resource_group_name = azurerm_resource_group.deployer[0].name
  location            = azurerm_resource_group.deployer[0].location
  name                = format("%s-msi", local.prefix)
}

data "azurerm_subscription" "primary" {}
data "azurerm_client_config" "current" {}

// Add role to be able to deploy resources
resource "azurerm_role_assignment" "sub_contributor" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.deployer.principal_id
}

// Add role to be able to create lock on rg 
resource "azurerm_role_assignment" "sub_user_admin" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "User Access Administrator"
  principal_id         = azurerm_user_assigned_identity.deployer.principal_id
}

// Linux Virtual Machine for Deployer
resource "azurerm_linux_virtual_machine" "deployer" {
  count                           = length(local.deployers)
  name                            = format("%s-%s%02d", local.prefix, local.deployers[count.index].name, count.index)
  computer_name                   = format("%s%02d", replace(replace(local.deployers[count.index].name, "-", ""), "_", ""), count.index)
  location                        = azurerm_resource_group.deployer[0].location
  resource_group_name             = azurerm_resource_group.deployer[0].name
  network_interface_ids           = [azurerm_network_interface.deployer[count.index].id]
  size                            = local.deployers[count.index].size
  admin_username                  = local.deployers[count.index].authentication.username
  admin_password                  = lookup(local.deployers[count.index].authentication, "password", null)
  disable_password_authentication = local.deployers[count.index].authentication.type != "password" ? true : false

  os_disk {
    name                 = format("%s-%s%02d-osdisk", local.prefix, local.deployers[count.index].name, count.index)
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

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.deployer.id]
  }

  dynamic "admin_ssh_key" {
    for_each = range(local.deployers[count.index].authentication.sshkey.public_key == null ? 0 : 1)
    content {
      username   = local.deployers[count.index].authentication.username
      public_key = local.deployers[count.index].authentication.sshkey.public_key
    }
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.deployer[0].primary_blob_endpoint
  }

  tags = {
    JumpboxName = "Deployer"
  }

  connection {
    type        = "ssh"
    host        = azurerm_public_ip.deployer[count.index].ip_address
    user        = local.deployers[count.index].authentication.username
    private_key = local.deployers[count.index].authentication.type == "key" ? local.deployers[count.index].authentication.sshkey.private_key : null
    password    = lookup(local.deployers[count.index].authentication, "password", null)
    timeout     = var.ssh-timeout
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
    private_key = local.deployers[count.index].authentication.type == "key" ? local.deployers[count.index].authentication.sshkey.private_key : null
    password    = lookup(local.deployers[count.index].authentication, "password", null)
    timeout     = var.ssh-timeout
  }

  provisioner "remote-exec" {
    inline = local.deployers[count.index].os.source_image_id != "" ? [] : [
      // Prepare folder structure
      "mkdir -p $HOME/Azure_SAP_Automated_Deployment/WORKSPACES/LOCAL/${azurerm_resource_group.deployer[0].name}",
      "mkdir $HOME/Azure_SAP_Automated_Deployment/WORKSPACES/SAP_LIBRARY",
      "mkdir $HOME/Azure_SAP_Automated_Deployment/WORKSPACES/SAP_SYSTEM",
      "mkdir $HOME/Azure_SAP_Automated_Deployment/WORKSPACES/SAP_LANDSCAPE",
      "mkdir $HOME/Azure_SAP_Automated_Deployment/WORKSPACES/DEPLOYER",
      // Clones project repository
      "git clone https://github.com/Azure/sap-hana.git $HOME/Azure_SAP_Automated_Deployment/sap-hana",
      // Install terraform for all users
      "sudo apt-get install unzip",
      "sudo mkdir -p /opt/terraform/terraform_0.12.29",
      "sudo mkdir -p /opt/terraform/bin/",
      "sudo wget -P /opt/terraform/terraform_0.12.29 https://releases.hashicorp.com/terraform/0.12.29/terraform_0.12.29_linux_amd64.zip",
      "sudo unzip /opt/terraform/terraform_0.12.29/terraform_0.12.29_linux_amd64.zip -d /opt/terraform/terraform_0.12.29/",
      "sudo ln -s /opt/terraform/terraform_0.12.29/terraform /opt/terraform/bin/terraform",
      "sudo sh -c \"echo export PATH=$PATH:/opt/terraform/bin > /etc/profile.d/deploy_server.sh\"",
      // Set env for MSI
      "sudo sh -c \"echo export ARM_USE_MSI=true >> /etc/profile.d/deploy_server.sh\"",
      "sudo sh -c \"echo export ARM_SUBSCRIPTION_ID=${data.azurerm_subscription.primary.subscription_id} >> /etc/profile.d/deploy_server.sh\"",
      "sudo sh -c \"echo export ARM_TENANT_ID=${data.azurerm_subscription.primary.tenant_id} >> /etc/profile.d/deploy_server.sh\"",
      "sudo sh -c \"echo az login --identity --output none >> /etc/profile.d/deploy_server.sh\"",
      // Install az cli
      "curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash",
      // Install Git
      "sudo apt update",
      "sudo apt-get install git=1:2.7.4-0ubuntu1.6",
      // install jq
      "sudo apt -y install jq=1.5+dfsg-2",
      // Install pip3
      "sudo apt -y install python3-pip",
      // Installs Ansible
      "sudo -H pip3 install \"ansible>=2.8,<2.9\"",
      // Install pywinrm
      "sudo -H pip3 install \"pywinrm>=0.3.0\""
    ]
  }
}
