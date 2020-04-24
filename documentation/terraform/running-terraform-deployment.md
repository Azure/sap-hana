### <img src="../../../documentation/assets/UnicornSAPBlack256x256.png" width="64px"> SAP Automation > V2 > HANA <!-- omit in toc -->
# Running the Terraform Deployment <!-- omit in toc -->

Master Branch's status: [![Build Status](https://dev.azure.com/azuresaphana/Azure-SAP-HANA/_apis/build/status/Azure.sap-hana.v2?branchName=master)](https://dev.azure.com/azuresaphana/Azure-SAP-HANA/_build/latest?definitionId=6&branchName=master)

<br>

## Table of contents <!-- omit in toc -->
- [Running the Terraform deployment](#running-the-terraform-deployment)

<br>

## Running the Terraform deployment


3. Initialize - Initialize the Terraform Workspace
4. Plan - Plan it. Terraform performs a deployment check.
5. Apply - Execute deployment.

<br><br><br>

## Terraform Operations

- From the Workspace directory that you created.

### Initialize

- Initializes the Workspace by linking in the path to the runtime code and downloading execution Providers.
- To re-initialize, add the `--upgrade=true` switch.

```bash
terraform init <automation_root>/sap-hana/deploy/v2/terraform-units/workspace/SAP_Library/TFE

or

terraform init --upgrade=true <automation_root>/sap-hana/deploy/v2/terraform-units/workspace/SAP_Library/TFE
```

<br>

### Plan

- A plan tests the *code* to see what changes will be made.
- If a Statefile exists, it will compare the *code*, the *statefile*, and the *resources* in Azure in order to detect drift and will display any changes or corrections that will result, and the actions that will be performed.

  ```bash
  terraform plan -var-file=<JSON configuration file> <automation_root>/sap-hana/deploy/v2/terraform
  ```

<br>

### Apply

- Apply executes the work identified by the Plan.
- A Plan is also an implicit step in the Apply that will ask for confirmation.
- To automatically confirm, add the `--auto-approve` switch.

  ```bash
  terraform apply -var-file=<JSON configuration file> <automation_root>/sap-hana/deploy/v2/terraform

  or

  terraform apply --auto-approve -var-file=<JSON configuration file> <automation_root>/sap-hana/deploy/v2/terraform
  ```

<br>

## Outputs

After the deployment finishes, you will see a message like the one below:

```bash
Apply complete! Resources: 34 added, 0 changed, 0 destroyed.

Outputs:

jumpbox-public-ip-address = xx.xxx.xx.xxx
jumpbox-username = xxx
``` 
