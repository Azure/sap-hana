### <img src="../../documentation/assets/UnicornSAPBlack256x256.png" width="64px"> SAP Automation > V1.0.0 <!-- omit in toc -->
# Automated SAP Deployments in Azure Cloud <!-- omit in toc -->

Master Branch's status: [![Build Status](https://dev.azure.com/azuresaphana/Azure-SAP-HANA/_apis/build/status/Azure.sap-hana?branchName=master&api-version=5.1-preview.1)](https://dev.azure.com/azuresaphana/Azure-SAP-HANA/_build/latest?definitionId=6&branchName=master)

<br>

## Table of contents <!-- omit in toc -->

- [Supported Scenarios](#supported-scenarios)
  - [Available](#available)
- [Usage](#usage)
- [What will be deployed](#what-will-be-deployed)
  - [Resources deployed](#resources-deployed)
    - [Common Infrastructure Resources](common-infrastructure-resources)
    - [HANA Database Resources](hana-database-resources)
    - [Application Tier Resources](application-tier-resources)
    - [Jumpbox Resources](jumpbox-resources)

<br>

## Supported Scenarios

### Available

- [HANA Scale-Up Stand Alone](/deploy/template_samples/single_node_hana.json)
- [HANA with High Availability](/deploy/template_samples/clustered_hana.json)

<br>

## Usage

A typical deployment lifecycle will require the following steps:

1. [**Initialize the Deployment Workspace**](/documentation/terraform/deployment-environment.md)
2. [**Adjusting the templates**](/documentation/json-adjusting-template.md#adjusting-the-templates)
3. [**Running Terraform deployment**](/documentation/terraform/running-terraform-deployment.md)
4. [**Running Ansible Playbook**](/documentation/ansible/running-ansible-playbook.md)
5. [**Deleting the deployment**](/documentation/terraform/deleting-the-deployment.md) (optional)

   *(**Note**: There are some script under [sap-hana/util](https://github.com/Azure/sap-hana/tree/master/util) would help if you are using Linux based workstation)*

<br>

---

## What will be deployed

Depending on the configuration (for examples, see the [Sample Templates](/deploy/template_samples/)) the following resources can be deployed:

1. **Common Infrastructure**
   - Resource Group
   - Management VNet
   - Management SubNet and Network Security Group (NSG)
   - SAP VNet
   - Storage Account for SAP Media downloads
   - Proximity Placement Group
   - iSCSI SubNet, NSG and Network Security Rules (NSR)
   - iSCSI VMs
1. **HANA Database**
   - Administration SubNet, NSG, and NSR
   - Database SubNet, NSG, and NSR
   - HDB Availability Set and Load Balancer
   - HDB VMs with Data Disks
1. **Application Tier**
   - Application Tier SubNet, NSG, and NSR
   - SAP Central Services (SCS) Load Balancer and Rules
   - Web Dispatcher Load Balancer and Rules
   - Application, SCS, and Web Dispatcher Availability Sets
   - Application VMs (based on a count)
   - SCS VMs (Stand Alone or 2 VMs for High Availability)
   - Web Dispatcher VMs (based on a count)
1. **Jumpboxes**
   - Linux based VM Jumpbox
   - Windows based VM Jumpbox
   - Run Time Instance VM for Ansible Configuration

     *(**Note:** The Run Time Instance is a Linux jumpbox configured with the Ansible component for configuring the other Virtual machines deployed)*

### Resources Deployed

Below is a table of resources as viewed in the [Azure Portal](https://portal.azure.com).

Note: SID below will be the 3-character SAP System Identifier specified in the input template.

#### Common Infrastructure Resources

| <sub>NAME   (Examples)</sub>   | <sub>TYPE</sub>                       | <sub>Description</sub>                                |
|--------------------------------|---------------------------------------|-------------------------------------------------------|
| <sub>iscs-00</sub>             | <sub>Virtual Machine</sub>            | <sub>VMs acting as iSCSI devices</sub>                |
| <sub>iscs-00-nic</sub>         | <sub>Network interface</sub>          | <sub>NIC for iSCSI VM</sub>                           |
| <sub>iscs-00-osdisk</sub>      | <sub>Disk</sub>                       | <sub>Disk for iSCSI VM</sub>                          |
| <sub>nsg-mgmt</sub>            | <sub>Network security group</sub>     | <sub>NSG for management vnet</sub>                    |
| <sub>sabootdiag5f49a971</sub>  | <sub>Storage account</sub>            | <sub>Storage account for all VMs</sub>                |
| <sub>sapbits5f49a971</sub>     | <sub>Storage account</sub>            | <sub>Storage account for download SAP media</sub>     |
| <sub>test-ppg</sub>            | <sub>Proximity Placement Group</sub>  | <sub>Proximity Placement Group for all SAP VMs</sub>  |
| <sub>vnet-mgmt</sub>           | <sub>Virtual network</sub>            | <sub>Vnet for management (jumpboxes)</sub>            |
| <sub>vnet-sap</sub>            | <sub>Virtual network</sub>            | <sub>Vnet for sap (HANA database servers)</sub>       |

#### HANA Database Resources

| <sub>NAME   (Examples)</sub>  | <sub>TYPE</sub>                    | <sub>Description</sub>                                                                          |
|-------------------------------|------------------------------------|-------------------------------------------------------------------------------------------------|
| <sub>hana-SID-lb</sub>        | <sub>Load Balancer</sub>           | <sub>Load Balancer for HANA database server(s)</sub>                                            |
| <sub>hdb1-0</sub>             | <sub>Virtual machine</sub>         | <sub>HANA database server(s)</sub>                                                              |
| <sub>hdb1-0-admin-nic</sub>   | <sub>Network interface</sub>       | <sub>NIC for admin IP</sub>                                                                     |
| <sub>hdb1-0-backup-0</sub>    | <sub>Disk</sub>                    | <sub>Disks attach to HANA database server(s) (e.g. os, sap, data,   log, shared, backup)</sub>  |
| <sub>hdb1-0-db-nic</sub>      | <sub>Network interface</sub>       | <sub>NIC for database</sub>                                                                     |
| <sub>nsg-admin</sub>          | <sub>Network security group</sub>  | <sub>NSG for admin SubNet</sub>                                                                 |
| <sub>nsg-db</sub>             | <sub>Network security group</sub>  | <sub>NSG for db SubNet</sub>                                                                    |
| <sub>SID-as</sub>             | <sub>Availability Set</sub>        | <sub>Availability Set for HANA database server(s)</sub>                                         |

#### Application Tier Resources

| <sub>NAME   (Examples)</sub>  | <sub>TYPE</sub>                    | <sub>Description</sub>                                               |
|-------------------------------|------------------------------------|----------------------------------------------------------------------|
| <sub>SID_app-avset</sub>      | <sub>Availability Set</sub>        | <sub>Availability Set for Application server(s)</sub>                |
| <sub>SID_app00</sub>          | <sub>Virtual machine</sub>         | <sub>Application server(s)</sub>                                     |
| <sub>SID_app00-osdisk</sub>   | <sub>Disk</sub>                    | <sub>Disks attach to Application server(s) (e.g. os, data)</sub>     |
| <sub>SID_app-nic</sub>        | <sub>Network interface</sub>       | <sub>NIC for Application server(s)</sub>                             |
| <sub>SID_scs-alb</sub>        | <sub>Load Balancer</sub>           | <sub>Load Balancer for SAP Central Services (SCS) server(s)</sub>    |
| <sub>SID_scs-avset</sub>      | <sub>Availability Set</sub>        | <sub>Availability Set for SCS server(s)</sub>                        |
| <sub>SID_scs00</sub>          | <sub>Virtual machine</sub>         | <sub>SCS server(s)</sub>                                             |
| <sub>SID_scs00-osdisk</sub>   | <sub>Disk</sub>                    | <sub>Disks attach to SCS server(s) (e.g. os, data)</sub>             |
| <sub>SID_scs-nic</sub>        | <sub>Network interface</sub>       | <sub>NIC for SCS server(s)</sub>                                     |
| <sub>SID_web-alb</sub>        | <sub>Load Balancer</sub>           | <sub>Load Balancer for Web Dispatcher server(s)</sub>                |
| <sub>SID_web-avset</sub>      | <sub>Availability Set</sub>        | <sub>Availability Set for Web Dispatcher server(s)</sub>             |
| <sub>SID_web00</sub>          | <sub>Virtual machine</sub>         | <sub>Web Dispatcher server(s)</sub>                                  |
| <sub>SID_web00-osDisk</sub>   | <sub>Disk</sub>                    | <sub>Disks attach to Web Dispatcher server(s) (e.g. os, data)</sub>  |
| <sub>SID_web-nic</sub>        | <sub>Network interface</sub>       | <sub>NIC for Web Dispatcher server(s)</sub>                          |
| <sub>nsg-app</sub>            | <sub>Network security group</sub>  | <sub>NSG for Application SubNet</sub>                                |
| <sub>nsg-db</sub>             | <sub>Network security group</sub>  | <sub>NSG for db vnet</sub>                                           |


#### Jumpbox Resources

| <sub>NAME   (Examples)</sub>          | <sub>TYPE</sub>                   | <sub>Description</sub>                                                   |
|---------------------------------------|-----------------------------------|--------------------------------------------------------------------------|
| <sub>jumpbox-linux</sub>              | <sub>Virtual machine</sub>        | <sub>Linux jumpboxe(s) [0..n]</sub>                                      |
| <sub>jumpbox-linux-nic1</sub>         | <sub>Network interface</sub>      | <sub>NIC for linux jumpboxe(s)</sub>                                     |
| <sub>jumpbox-linux-osdisk</sub>       | <sub>Disk</sub>                   | <sub>Disks for linux jumpboxe(s)</sub>                                   |
| <sub>jumpbox-linux-public-ip</sub>    | <sub>Public IP address</sub>      | <sub>Public IP for linux jumpboxe(s)</sub>                               |
| <sub>jumpbox-windows</sub>            | <sub>Virtual machine</sub>        | <sub>Windows jumpboxe(s) [0..n]</sub>                                    |
| <sub>jumpbox-windows-nic1</sub>       | <sub>Network interface</sub>      | <sub>NIC for Windows jumpboxe(s)</sub>                                   |
| <sub>jumpbox-windows-osdisk</sub>     | <sub>Disk</sub>                   | <sub>Disks for Windows jumpboxe(s)</sub>                                 |
| <sub>jumpbox-windows-public-ip</sub>  | <sub>Public IP address</sub>      | <sub>Public IP for Windows jumpboxe(s)</sub>                             |
| <sub>rti</sub>                        | <sub>Virtual machine</sub>        | <sub>Linux Run Time Instance (RTI) jumpbox for Ansible Execution.</sub>  |
| <sub>rti-nic1</sub>                   | <sub>Network interface</sub>      | <sub>NIC for RTI</sub>                                                   |
| <sub>rti-osdisk</sub>                 | <sub>Disk</sub>                   | <sub>Disks for RTI</sub>                                                 |
| <sub>rti-public-ip</sub>              | <sub>Public IP address</sub>      | <sub>Public IP for RTI</sub>                                             |
