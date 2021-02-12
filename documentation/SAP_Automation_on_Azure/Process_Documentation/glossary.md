## Glossary

|Term|Description|
| :- | :- |
|System|An instance of an SAP application identified by a system ID (SID). Consists of one or more Virtual Machines and their supporting artifacts deployed to Azure to a resource group.|
|Landscape|A collection of instances of the same SAP Application, for instance a development instance, a quality assurance instance and the production instance. Consists of multiple systems each in their own resource group|
|Environment|provides a way to partition the SAP Applications in an SAP Landscape, for instance development-, quality assurance- and production environment. The environment deployment will provide shared resources to all the systems in the environment, for example virtual network, key vaults. It provides a way to partition the SAP Applications in an SAP Landscape, for instance development-, quality assurance- and production environment. The environment deployment will provide shared resources to all the systems in the environment, for example virtual network, key vaults.

## Deployment Artifacts

|Term|Description|Scope|
| :- | :- | :- |
|Deployer|The Deployer is a virtual machine that can be used to execute Terraform and Ansible commands. It is deployed to a virtual network (new or existing) that will be peered to the SAP Virtual Network|Environment|
|Library|This will provide storage for the Terraform state files and the SAP Installation Media|Region|
|Landscape/Environment| The environment will contain the Virtual Network into which the SAP Systems will be deployed. It will also contain Key Vault which will contain the credentials for the systems in the environment: deployer and systems(s) |Environment|
|System|The system is the deployment unit for the SAP Application (SID). It will contain the Virtual Machines and the supporting infrastructure artifacts (load balancers, availability sets etc)|Environment|

## System

The SAP system will contain the resources which are needed for the SAP application, these include the virtual machines, disks, load balancers, proximity placement groups, availability sets, subnets, network security groups etc. The system deployment leverages the key vaults from the environment deployment (sap\_landscape) for credentials management, the Virtual network information from the environment (sap\_landscape). The Terraform deployment will store its state file in the storage account defined in the environment (sap\_library)

## Environment

The environment will contain resources which are shared amongst all the systems, these include the virtual network, the key vaults used for credentials management, the storage accounts used for Terraform state management and for storing the SAP media. The table below lists all the components deployed by the first Terraform deployment steps to prepare the automation environment

## Landscape

Will use environment specific deployments and contain those resources needed for the specific realization of the SAP landscape including the systems 

![glossary](../assets/images/SAP_estate.png)