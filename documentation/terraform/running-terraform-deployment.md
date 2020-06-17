### <img src="../../documentation/assets/UnicornSAPBlack256x256.png" width="64px"> SAP Automation > V1.0.0 > HANA <!-- omit in toc -->
# Running the Terraform Deployment <!-- omit in toc -->

Master Branch's status: [![Build Status](https://dev.azure.com/azuresaphana/Azure-SAP-HANA/_apis/build/status/Azure.sap-hana?branchName=master&api-version=5.1-preview.1)](https://dev.azure.com/azuresaphana/Azure-SAP-HANA/_build/latest?definitionId=6&branchName=master)

<br>

## Table of contents <!-- omit in toc -->
- [Running the Terraform deployment](#running-the-terraform-deployment)
- [Terraform Operations](#terraform-operations)
  - [Initialize](#initialize)
  - [Plan](#plan)
  - [Apply](#apply)
- [Outputs](#outputs)

<br>

## Running the Terraform deployment


1. Initialize - Initialize the Terraform Workspace

2. Plan - Plan it. Terraform performs a deployment check.

3. Apply - Execute deployment.

<br><br><br>

## Terraform Operations

- From the Workspace directory that you created.

<br>

### Initialize

- Initializes the Workspace by linking in the path to the runtime code and downloading execution Providers.

  ```bash
  terraform init <automation_root>/sap-hana/deploy/terraform
  ```

- To re-initialize, add the `--upgrade=true` switch.

  ```bash
  terraform init --upgrade=true <automation_root>/sap-hana/deploy/terraform
  ```

<br>

### Plan

- A plan tests the *code* to see what changes will be made.
- If a Statefile exists, it will compare the *code*, the *statefile*, and the *resources* in Azure in order to detect drift and will display any changes or corrections that will result, and the actions that will be performed.

  ```bash
  terraform plan -var-file=<JSON configuration file> <automation_root>/sap-hana/deploy/terraform
  ```

<br>

### Apply

- Apply executes the work identified by the Plan.
- A Plan is also an implicit step in the Apply that will ask for confirmation.

  ```bash
  terraform apply -var-file=<JSON configuration file> <automation_root>/sap-hana/deploy/terraform
  ```

- To automatically confirm, add the `--auto-approve` switch.

  ```bash
  terraform apply --auto-approve -var-file=<JSON configuration file> <automation_root>/sap-hana/deploy/terraform
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
