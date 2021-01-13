### <img src="documentation/assets/UnicornSAPBlack256x256.png" width="64px"> SAP Automation <!-- omit in toc -->
# Automated SAP Deployments in Azure Cloud <!-- omit in toc -->
Master Branch's status: [![Build Status](https://dev.azure.com/azuresaphana/Azure-SAP-HANA/_apis/build/status/Azure.sap-hana.v2?branchName=master)](https://dev.azure.com/azuresaphana/Azure-SAP-HANA/_build/latest?definitionId=6&branchName=master)

This repository contains code that can be used to automatically deploy SAP landscapes in the Azure Cloud.

The templates are split into:
- **Terraform modules**
which deploy the infrastructure components (such as VMs, network, storage) in Azure.
- **Ansible playbooks**
which run different roles to configure and VMs and install SAP HANA and required applications on the already deployed infrastructure.

<br>

## Table of contents <!-- omit in toc -->

- [Usage](#usage)
- [Terraform Deployment Units](#terraform-deployment-units)
- [Contributions](#contributions)
- [License & Copyright](#license--copyright)
- [Contact](#contact)

<br>

## Usage

A typical deployment lifecycle will require the following steps:

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


<br><br><br><br>  

---

## Contributions

If you want to contribute to our project, be sure to review the [contributing guidelines](/CONTRIBUTING.md).

We use [GitHub issues](https://github.com/Azure/sap-hana/issues/) for feature requests and bugs.

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

<br>

## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft's privacy statement. Our privacy statement is located at https://go.microsoft.com/fwlink/?LinkID=824704. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.


## How to Turn off Data Collection

To turn off data collection, please remove or comment out this [line](https://github.com/Azure/sap-hana/blob/ea5d0aa75910b40e5604ab916dbaaac28d2779d4/deploy/terraform/ansible.tf#L56).

## License & Copyright

Copyright © 2018-2020 Microsoft Azure.

Licensed under the [MIT License](LICENSE).

<br>

## Contact

We look forward to your feedback and welcome any contributions!

Please feel free to reach out to our team at ![image](/documentation/assets/contact.png).
