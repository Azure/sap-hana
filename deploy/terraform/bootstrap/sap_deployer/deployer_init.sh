#!/usr/bin/env bash

# exit immediately if a command fails
set -o errexit

# exit immediately if an unset variable is used
set -o nounset

function main()
{
    check_command_line_arguments "$@"

    local deployer_rg_name="$1"
    local deployer_sub_id="$2"
    local deployer_tenant_id="$3"

    init "${deployer_rg_name}" "${deployer_sub_id}" "${deployer_tenant_id}"
}

function check_command_line_arguments()
{
    local args_count="$#"

    # Check if deployer_rg_name, deployer_sub_id and deployer_tenant_id are provided
    if [[ ${args_count} -ne 3 ]]; then
        echo "Please run deployer_init.sh <resource group name> <deployer subscription id> <deployer tenant id>"
        exit 1
    fi
}

function init()
{
    local deployer_rg_name="$1"
    local deployer_sub_id="$2"
    local deployer_tenant_id="$3"

    # Prepare folder structure
    mkdir -p $HOME/Azure_SAP_Automated_Deployment/WORKSPACES/LOCAL/$deployer_rg_name
    mkdir -p $HOME/Azure_SAP_Automated_Deployment/WORKSPACES/SAP_LIBRARY
    mkdir -p $HOME/Azure_SAP_Automated_Deployment/WORKSPACES/SAP_SYSTEM
    mkdir -p $HOME/Azure_SAP_Automated_Deployment/WORKSPACES/SAP_LANDSCAPE
    mkdir -p $HOME/Azure_SAP_Automated_Deployment/WORKSPACES/DEPLOYER

    # Clones project repository
    git clone https://github.com/Azure/sap-hana.git $HOME/Azure_SAP_Automated_Deployment/sap-hana || true

    # Install terraform for all users
    sudo apt-get install unzip
    sudo mkdir -p /opt/terraform/terraform_0.13.5
    sudo mkdir -p /opt/terraform/bin/
    sudo wget -c -P /opt/terraform/terraform_0.13.5 https://releases.hashicorp.com/terraform/0.13.5/terraform_0.13.5_linux_amd64.zip
    sudo unzip -u /opt/terraform/terraform_0.13.5/terraform_0.13.5_linux_amd64.zip -d /opt/terraform/terraform_0.13.5/
    sudo ln -sf /opt/terraform/terraform_0.13.5/terraform /opt/terraform/bin/terraform
    sudo sh -c "echo export PATH=$PATH:/opt/terraform/bin > /etc/profile.d/deploy_server.sh"
    
    # Set env for MSI
    sudo sh -c "echo export ARM_USE_MSI=true >> /etc/profile.d/deploy_server.sh"
    sudo sh -c "echo export ARM_SUBSCRIPTION_ID=${deployer_sub_id} >> /etc/profile.d/deploy_server.sh"
    sudo sh -c "echo export ARM_TENANT_ID=${deployer_tenant_id} >> /etc/profile.d/deploy_server.sh"
    sudo sh -c "echo az login --identity --output none >> /etc/profile.d/deploy_server.sh"
    
    # Install az cli
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    
    # Install Git
    sudo apt update
    sudo apt-get install git=1:2.7.4-0ubuntu1.6
    
    # install jq
    sudo apt -y install jq=1.5+dfsg-2
    
    # Install pip3
    sudo apt -y install python3-pip
    
    # Installs Ansible
    sudo -H pip3 install "ansible>=2.8,<2.9"
    
    # Install pywinrm
    sudo -H pip3 install "pywinrm>=0.3.0"
}

# Execute the main program flow with all arguments
main "$@"
