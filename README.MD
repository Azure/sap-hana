### <img src="documentation/SAP_Automation_on_Azure/assets/images/UnicornSAPBlack256x256.png" width="64px"> SAP Deployment Automation Framework <!-- omit in toc -->
<br/>

# Welcome <!-- omit in toc -->

Master Branch's status: [![Build Status](https://dev.azure.com/azuresaphana/Azure-SAP-HANA/_apis/build/status/Azure.sap-hana?branchName=master&api-version=5.1-preview.1)](https://dev.azure.com/azuresaphana/Azure-SAP-HANA/_build/latest?definitionId=6&branchName=master)

<br/><br/>

## Abstract <!-- omit in toc -->

---
<br/>

Welcome to the **SAP on Azure Deployment Automation Framework** repository.
This repository contains code that will support the automated deployments of SAP platforms in the Azure Cloud.
<br/>

Please follow the linke below to the documentation:
<br/><br/>


<center>

[<img src="documentation/SAP_Automation_on_Azure/assets/images/documentation-clipart.png" width="256px">](documentation/SAP_Automation_on_Azure/table_of_contents.md)

## [SAP Deployment Automation Framework Documentation](documentation/SAP_Automation_on_Azure/table_of_contents.md) <!-- omit in toc -->

</center>


<br/><br/><br/>


# Table of contents <!-- omit in toc -->

- [Contributions](#contributions)
- [Data Collection](#data-collection)
- [How to Turn off Data Collection](#how-to-turn-off-data-collection)
- [License & Copyright](#license--copyright)
- [Contact](#contact)

<br/><br/>

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

To turn off data collection, please remove or comment out below IMDS.tf files:
- Data collection for deployer [here](https://github.com/Azure/sap-hana/blob/master/deploy/terraform/terraform-units/modules/sap_deployer/IMDS.tf)
- Data collection for sap_library [here](https://github.com/Azure/sap-hana/blob/master/deploy/terraform/terraform-units/modules/sap_library/IMDS.tf)
- Data collection for sap_landscape [here](https://github.com/Azure/sap-hana/blob/master/deploy/terraform/terraform-units/modules/sap_landscape/IMDS.tf)
- Data collection for sap_system [here](https://github.com/Azure/sap-hana/blob/master/deploy/terraform/terraform-units/modules/sap_system/common_infrastructure/IMDS.tf)


## License & Copyright

Copyright © 2018-2020 Microsoft Azure.

Licensed under the [MIT License](LICENSE).

<br>

## Contact

We look forward to your feedback and welcome any contributions!

Please feel free to reach out to our team at ![image](documentation/SAP_Automation_on_Azure/assets/images/contact.png).
