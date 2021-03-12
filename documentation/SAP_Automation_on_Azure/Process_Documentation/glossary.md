## Glossary

|Term|Description|
| :- | :- |
|System|An SAP system is an instance of an SAP application that has the resources the application needs to run, like virtual machines (VMs), disks, load balancers, proximity placement groups, availability sets, subnets, and network security groups. The application is identified by a unique 3 letter identifier SID.|
|Landscape|A landscape is a collection of systems in different environments in an SAP application. The example diagram shows three SAP landscapes: SAP ERP Central Component (ECC), SAP customer relationship management (CRM), and SAP Business Warehouse (BW).|
|Workload Zone|A workload zone is also called a deployment environment, and partitions the SAP application into environments like non-prod and prod or can further segment a landscape into tiers like development, quality assurance, and production. A deployment environment provides shared resources like virtual networks and key vaults to all the systems in the Workload Zone.

The following diagram illustrates the dependencies between SAP systems, workload zones, and landscapes. In the illustration below the customer has three landscapes: SAP ERP Central Component (ECC), SAP customer relationship management (CRM), and SAP Business Warehouse (BW). Each landscape has four workload zones: sandbox, development, quality assurance, and production. Each workload zone may contain one or more systems.

<img src="../assets/images/SAP_estate.png" width=500px>

**Figure 1 SAP Application Estate**

## Deployment Artifacts

|Term|Description|Scope|
| :- | :- | :- |
|Deployer|The Deployer is a virtual machine that can be used to execute Terraform and Ansible commands. It is deployed to a virtual network (new or existing) that will be peered to the SAP Virtual Network. For more info see [Deployer](../Software_Documentation/product_documentation-deployer.md)|Region.
|Library|This will provide storage for the Terraform state files and the SAP Installation Media. [Library](../Software_Documentation/product_documentation-sap_library.md)|Region|
|Workload Zone| The environment will contain the Virtual Network into which the SAP Systems will be deployed. It will also contain Key Vault which will contain the credentials for the systems in the environment. For more info see [Workload Zone](../Software_Documentation/product_documentation-sap-workloadzone.md) |Workload Zone|
|System|The system is the deployment unit for the SAP Application (SID). It will contain the Virtual Machines and the supporting infrastructure artifacts (load balancers, availability sets etc). For more info see [System](../Software_Documentation/product_documentation-sap_deployment_unit.md)|Workload Zone|

