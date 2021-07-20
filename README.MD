# ![SAP Deployment Automation Framework](/documentation/SAP_Automation_on_Azure/assets/images/UnicornSAPBlack64x64.png) **SAP Deployment Automation Framework** #

Welcome to the [**SAP on Azure Deployment Automation Framework**](documentation/SAP_Automation_on_Azure/table_of_contents.md) repository.

This repository contains the tooling designed to enable automated deployment for SAP on Azure. The automation framework leverages [Terraform](https://www.terraform.io/) for the infrastructure deployment and [Ansible](https://www.ansible.com/) for operating system and application configuration. It allows for deployment of the infrastructure for SAP landscapes based on SAP HANA and NetWeaver with AnyDB using all SAP supported operating system versions. All SAP tiers – SBX, DEV, QA, PROD can be deployed in a chosen region.

The deployment framework is based on Microsoft best practices and principles for SAP on Azure. These principles are outlined in a comprehensive documentation which should be followed to ensure supportability by using certified virtual machines and storage solutions, stability, reliability and performance. [Get started with SAP on Azure VMs - Azure Virtual Machines | Microsoft Docs](https://docs.microsoft.com/azure/virtual-machines/workloads/sap/get-started)

The principles of the SAP Automation frameworks adhers to the principles of the Microsoft cloud adoption framework. [Microsoft Cloud Adoption Framework for Azure - Cloud Adoption Framework | Microsoft Docs](https://docs.microsoft.com/azure/cloud-adoption-framework/)

## Glossary ##

|Term           | Description|
| :-            | :-         |
|System         |An SAP system is an instance of an SAP application that has the resources the application needs to run, like virtual machines (VMs), disks, load balancers, proximity placement groups, availability sets, subnets, and network security groups. The application is identified by a unique 3 letter identifier SID.|
|Environment    |An Environment is defined as a distinct tier along an SAP transport path, for example Sandbox, Development, QA, or Production. Each environment can contain a number of Systems.|
|Landscape      |A landscape is a collection of systems in different environments in an SAP application. The example diagram below shows three SAP landscapes, each containing 3 Systems: SAP ERP (D10/Q10/P10), SAP CRM (D20/Q20/P30), and SAP BW (D30/Q30/P30).|
|Workload Zone  |A workload zone is also called a deployment environment, and partitions the SAP application into environments like non-prod and prod or can further segment a landscape into tiers like development, quality assurance, and production. A deployment environment provides shared resources like virtual networks and key vaults to all the systems in the Workload Zone.  

<br>

The following diagram illustrates the dependencies between SAP systems, workload zones, and landscapes. In the illustration below the customer has three landscapes: SAP ERP Central Component (ECC), SAP customer relationship management (CRM), and SAP Business Warehouse (BW). Each landscape has four workload zones: sandbox, development, quality assurance, and production. Each workload zone may contain one or more systems.

![SAP Deployment Automation Framework - Process](/documentation/images/SAP_estate.png)

## SAP Deployment Automation Framework - Process ##

The highlevel process for deployment is illustrated in the diagram below.

![SAP Deployment Automation Framework - Process](/documentation/images/SAP-Automation_Process.png)

### **Deployment environment** ###

The first deployment activity is to prepare the deployment environment. This environment will contain a an Azure virtual machine that can be used to run Terraform and Ansible. The environment will also contain a keyvault for storing credential information. For more information see [Deployer documentation](/documentation/SAP_Automation_on_Azure/Software_Documentation/product_documentation-deployer.md) and [Deployer configuration](/documentation/SAP_Automation_on_Azure/Software_Documentation/configuration-deployer.md)

![SAP Deployment Automation Framework - Deployer](/documentation/images/Deployer.png)

### **SAP Library** ###

The SAP library will provide persistent storage for the Terraform state files as well as storage for the SAP Installation media. For more information see [SAP Library documentation](/documentation/SAP_Automation_on_Azure/Software_Documentation/product_documentation-sap_library.md) and [SAP Library configuration](/documentation/SAP_Automation_on_Azure/Software_Documentation/configuration-sap_library.md)

![SAP Deployment Automation Framework - Library](/documentation/images/Library.png)

### **Workload zone** ###

The workload zone will support the partitioning of an SAP landscape into different tiers (Dev, QA, Prod, etc). The workload zone will contain an Azure Virtual Network and Azure Keyvaults for managing the virtual machine credentials for the systems deployed into the workload. For more information see [SAP Workload Zone documentation](/documentation/SAP_Automation_on_Azure/Software_Documentation/product_documentation-sapworkloadzone.md) and [SAP Workload Zone configuration](/documentation/SAP_Automation_on_Azure/Software_Documentation/configuration-sap_workloadzone.md)

![SAP Deployment Automation Framework - Workload zone](/documentation/images/Workload_zone.png)

### **System** ###

The SAP System is the actual SAP Application, it contains all the Azure artifacts required to host the SAP Application.

For more information see [SAP System documentation](/documentation/SAP_Automation_on_Azure/Software_Documentation/product_documentation-sap_deployment_unit.md) and [SAP System configuration](/documentation/SAP_Automation_on_Azure/Software_Documentation/configuration--sap_deployment_unit.md)

![SAP Deployment Automation Framework - Workload zone](/documentation/images/system.png)

### Getting started with the SAP Deployment Automation Framework ###

For detailed guidance on how to start using the Deployment Automation Framework see: [Getting started with the SAP Deployment Automation framework](/documentation/SAP_Automation_on_Azure/Process_Documentation/readme.md)

### Contributing to the repository ###


For information about how to collaborate in the repository please see the [contributing guidelines](contributions.md)
