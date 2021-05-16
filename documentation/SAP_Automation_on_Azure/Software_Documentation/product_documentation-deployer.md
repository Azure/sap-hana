# ![SAP Deployment Automation Framework](../assets/images/UnicornSAPBlack64x64.png)**SAP Deployment Automation Framework** #

## Deployment infrastructure ##

The deployment environment provides the following services

1. Deployment Virtual Machine, this virtual machine can be used to perform both the Terraform deployments as well as the Ansible configurations.
2. Azure Keyvault, this keyvault will containg the Service Principal details and will be used by the Terraform deployments
3. Azure Firewall, this optional component is used to provide outbound Internet connectivity.

![SAP Deployment Automation Framework - Deployer](../../images/deployer.png)

## Deployer VM ##

The default Deployer VM is an Ubuntu 18.4 Linux Server. It has a clone of the Github sap-hana repository and both Terraform and Ansible installed.

## Azure Key Vault ##

The Azure Key Vault will be used to host the Service Principal account details. The automation will always deploy a pair of Key Vaults, the "user" Key Vault which is intended for administrative users and "prvt" which is intended for the automation only.

**Note** The credentials for the Deployer VM will be stored in the "user" Key Vault.

## Azure Firewall ##

The Azure Firewall will be used to provide outbount Internet Connectivity

## Configuration ##

The configuration of the deployment infrastructure is documented here: [Deployer configuration](./configuration-deployer.md)
