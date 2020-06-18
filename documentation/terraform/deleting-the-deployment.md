### <img src="../../documentation/assets/UnicornSAPBlack256x256.png" width="64px"> SAP Automation > V1.0.0 > HANA <!-- omit in toc -->
# Deleting the Deployment <!-- omit in toc -->

Master Branch's status: [![Build Status](https://dev.azure.com/azuresaphana/Azure-SAP-HANA/_apis/build/status/Azure.sap-hana?branchName=master&api-version=5.1-preview.1)](https://dev.azure.com/azuresaphana/Azure-SAP-HANA/_build/latest?definitionId=6&branchName=master)

<br>

## Table of contents <!-- omit in toc -->

- [Deleting the Deployment](#deleting-the-deployment)

<br>

## Deleting the Deployment

- If you don't need the deployment anymore, you can remove it just as easily.
  <br>From the Workspace directory, run the following command to remove all deployed resources:

  ```bash
  terraform destroy -var-file=<JSON configuration file> <automation_root>/sap-hana/deploy/terraform
  ```

- To automatically confirm, add the `--auto-approve` switch.

  ```bash
  terraform destroy --auto-approve -var-file=<JSON configuration file> <automation_root>/sap-hana/deploy/terraform
  ```
