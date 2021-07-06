/*
Description:

  Configures the Deployer after creation.

*/

// Prepare deployer with pre-installed softwares if pip is created
resource "null_resource" "prepare-deployer" {
  depends_on = [azurerm_linux_virtual_machine.deployer]
  count      = local.enable_deployer_public_ip ? length(local.deployers) : 0

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
      //
      // Prepare folder structure
      //
      "mkdir -p $HOME/Azure_SAP_Automated_Deployment/WORKSPACES/LOCAL/${local.rg_name}",
      "mkdir $HOME/Azure_SAP_Automated_Deployment/WORKSPACES/LIBRARY",
      "mkdir $HOME/Azure_SAP_Automated_Deployment/WORKSPACES/SYSTEM",
      "mkdir $HOME/Azure_SAP_Automated_Deployment/WORKSPACES/LANDSCAPE",
      "mkdir $HOME/Azure_SAP_Automated_Deployment/WORKSPACES/DEPLOYER",
      //
      // Clones project repository
      //
      "git clone https://github.com/Azure/sap-hana.git $HOME/Azure_SAP_Automated_Deployment/sap-hana",
      //
      // Install terraform for all users
      //
      "sudo apt-get install unzip",
      "tfversion=",
      "tfdir=0.14.7",
      "sudo mkdir -p /opt/terraform/terraform_0.14.7",
      "sudo mkdir -p /opt/terraform/bin/",
      "sudo wget -P /opt/terraform/terraform_0.14.7 https://releases.hashicorp.com/terraform/0.14.7/terraform_0.14.7_linux_amd64.zip",
      "sudo unzip /opt/terraform/terraform_0.14.7/terraform_0.14.7_linux_amd64.zip -d /opt/terraform/terraform_0.14.7/",
      "sudo ln -s /opt/terraform/terraform_0.14.7/terraform /opt/terraform/bin/terraform",
      "sudo sh -c \"echo export PATH=$PATH:/opt/terraform/bin > /etc/profile.d/deploy_server.sh\"",
      //
      // Set env for MSI
      //
      "sudo sh -c \"echo export ARM_USE_MSI=true >> /etc/profile.d/deploy_server.sh\"",
      "sudo sh -c \"echo export ARM_MSI_ENDPOINT=\"http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01\" >> /etc/profile.d/deploy_server.sh\"",
      "sudo sh -c \"echo export ARM_CLIENT_ID=${azurerm_user_assigned_identity.deployer.client_id} >> /etc/profile.d/deploy_server.sh\"",
      "sudo sh -c \"echo export ARM_SUBSCRIPTION_ID=${data.azurerm_subscription.primary.subscription_id} >> /etc/profile.d/deploy_server.sh\"",
      "sudo sh -c \"echo export ARM_TENANT_ID=${data.azurerm_subscription.primary.tenant_id} >> /etc/profile.d/deploy_server.sh\"",
      "sudo sh -c \"echo export DEPLOYMENT_REPO_PATH=$HOME/Azure_SAP_Automated_Deployment/sap-hana >> /etc/profile.d/deploy_server.sh\"",
      "sudo sh -c \"echo az login --identity --output none >> /etc/profile.d/deploy_server.sh\"",
      //
      // Set env for ansible
      //
      "sudo sh -c \"echo export ANSIBLE_HOST_KEY_CHECKING=False >> /etc/profile.d/deploy_server.sh\"",
      //
      // Install az cli
      //
      "curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash",
      "sudo apt update",
      //
      // install jq
      //
      "sudo apt -y install jq",
      "sudo pip3 pip install setuptools-rust",
      //
      // Install pip
      //
      "sudo apt -y install python3-pip",
      "sudo pip3 install --upgrade pip",
      "sudo pip3 pip install msal",
      //
      // Installs Ansible
      //
      "sudo pip3 install \"ansible>=2.9,<2.10\"",
      "sudo pip3 install ansible[azure]",
      "sudo -H wget -nv -q https://raw.githubusercontent.com/ansible-collections/azure/dev/requirements-azure.txt",
      "sudo -H pip3 install -r requirements-azure.txt",
      "sudo -H ansible-galaxy collection install azure.azcollection --force",
      //
      // Install pywinrm
      //
      "sudo pip3 install \"pywinrm>=0.3.0\"",
      //
      // Install yamllint
      //
      "sudo pip3 install yamllint",
      //
      // Install ansible-lint
      //
      "sudo pip3 install ansible-lint \"ansible>=2.9,<2.10\"",
      "sudo pip3 install argcomplete",
      "sudo activate-global-python-argcomplete"
    ]
  }
}
