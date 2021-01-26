The templates are split into:
- **Terraform modules**
which deploy the infrastructure components (such as VMs, network, storage) in Azure.
- **Ansible playbooks**
which run different roles to configure and VMs and install SAP HANA and required applications on the already deployed infrastructure.

<br>

## Usage

A typical deployment lifecycle will require the following steps:

Step 1) [**Bootstrap the Deployment Platform**](/documentation/deployment-platform-bootstrap.md) (this has to be done only once)

Step 2) [Deploy SAP Library]()

Step 3) [Deploy SAP Workload VNET]()

Step 4) [Deploy SDU]()

Step 1) [**Preparing your environment**](/documentation/getting-started.md#preparing-your-environment) (this has to be done only once)

Step 2) [**Select Terraform Deployment Unit**](#terraform-deployment-units)


Step 1) [**Preparing your environment**](/documentation/getting-started.md#preparing-your-environment) (this has to be done only once)

Step 2) [**Select Terraform Deployment Unit**](#terraform-deployment-units)

   *(**Note**: There are some script under [sap-hana/util](https://github.com/Azure/sap-hana/tree/master/util) would help if you are using Linux based workstation)*

<br>

## Terraform Deployment Units

- [SAP Landscape](/deploy/terraform/SAPLandscape.md) (Primary Entry Point)
- [SAP Library](/deploy/terraform-units/workspace/SAP_Library/Readme.md)
- Deployment Portal (Coming Soon)
- Logical SAP Network Foundation (Coming Soon)
- SDU - SAP Deployment Unit (Coming Soon)

