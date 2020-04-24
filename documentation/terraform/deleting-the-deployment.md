### <img src="../../documentation/assets/UnicornSAPBlack256x256.png" width="64px"> SAP Automation > V2 > HANA <!-- omit in toc -->
# Deleting the Deployment <!-- omit in toc -->

Master Branch's status: [![Build Status](https://dev.azure.com/azuresaphana/Azure-SAP-HANA/_apis/build/status/Azure.sap-hana.v2?branchName=master)](https://dev.azure.com/azuresaphana/Azure-SAP-HANA/_build/latest?definitionId=6&branchName=master)

<br>

## Table of contents <!-- omit in toc -->

- [Deleting the Deployment](#deleting-the-deployment)

<br>

## Deleting the Deployment

1. If you don't need the deployment anymore, you can remove it just as easily.
From the Workspace directory, run the following command to remove all deployed resources:

- To automatically confirm, add the `--auto-approve` switch.

```
terraform destroy -var-file=<JSON configuration file> <automation_root>/sap-hana/deploy/v2/terraform

or

terraform destroy --auto-approve -var-file=<JSON configuration file> <automation_root>/sap-hana/deploy/v2/terraform
```
