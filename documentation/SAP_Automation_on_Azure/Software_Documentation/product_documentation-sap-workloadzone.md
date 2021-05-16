# ![SAP Deployment Automation Framework](../assets/images/UnicornSAPBlack64x64.png)**SAP Deployment Automation Framework** #


## SAP Workload Zone ##

An SAP Application has typically multiple development tiers, for instance development, quality assurance and production. The SAP Deployment Automation refers to these as workload zones.

A workload zone combines the workload Virtual Network and the set of credentials to be used in the systems in that workload as well as the Service Principal that is used for deploying systems. The Workload Zones are regional because they depend on the Azure Virtual Network. The naming convention of the automation supports having workload zones in multiple Azure regions each with their own virtual network.

The Workload Zone provides the following services:

- Azure Virtual Network (including subnets and network security groups)
- Azure Keyvault for system credentials
- Storage account for bootdiagnostics
- Storage account for cloud witness

![SAP Deployment Automation Framework - Workload Zone](../../images/workload_zone.png)

## Configuration ##

The configuration of the SAP Workload is documented here: [SAP Workload zone configuration](./configuration-sap_workloadzone.md)
