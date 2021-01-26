### <img src="../../../assets/images/UnicornSAPBlack256x256.png" width="64px"> SAP Deployment Automation Framework <!-- omit in toc -->
<br/><br/>

# Logical SAP Workload VNET <!-- omit in toc -->

<br/>

## Table of contents <!-- omit in toc -->

- [Overview](#overview)
- [Notes](#notes)
- [Procedure](#procedure)
  - [Logical SAP Workload VNET](#logical-sap-workload-vnet)

<br/>

## Overview

![Block4](assets/Block4.png)
|                  |              |
| ---------------- | ------------ |
| Duration of Task | `5 minutes`  |
| Steps            | `6`          |
| Runtime          | `1 minutes`  |

---

<br/><br/>

## Notes

- For the workshop the *default* naming convention is referenced and used. For the **Deployer** there are three fields.
  - `<ENV>`-`<REGION>`-`<SAP_VNET>`-INFRASTRUCTURE

    | Field        | Legnth   | Value  |
    | ------------ | -------- | ------ |
    | `<ENV>`      | [5 CHAR] | NP     |
    | `<REGION>`   | [4 CHAR] | EUS2   |
    | `<SAP_VNET>` | [7 CHAR] | SAP00  |
  
    Which becomes this: **NP-EUS2-SAP00-INFRASTRUCTURE**
    
    This is used in several places:
    - The path of the Workspace Directory.
    - Input JSON file name
    - Resource Group Name.

    You will also see elements cascade into other places.

<br/><br/>

## Procedure

### Logical SAP Workload VNET

<br/>

1. Create Working Directory.
    <br/>*`Observe Naming Convention`*<br/>
    ```bash
    mkdir -p ~/Azure_SAP_Automated_Deployment/WORKSPACES/SAP_LANDSCAPE/NP-EUS2-SAP00-INFRASTRUCTURE; cd $_
    ```
    <br/>

2. Create *backend* parameter file.
    <br/>*`Observe Naming Convention`*<br/>
    ```bash
    cat <<EOF > backend
    resource_group_name   = "NP-EUS2-SAP_LIBRARY"
    storage_account_name  = "<tfstate_storage_account_name>"
    container_name        = "tfstate"
    key                   = "NP-EUS2-SAP00-INFRASTRUCTURE.terraform.tfstate"
    EOF
    ```
    |                      |           |
    | -------------------- | --------- |
    | resource_group_name  | The name of the Resource Group where the TFSTATE Storage Account is located. |
    | storage_account_name | The name of the Storage Account that was deployed durring the SAP_LIBRARY deployment, used used for the TFSTATE files. |
    | key                  | A composit of the `SAP Workload VNET` Resource Group name and the `.terraform.tfstate` extension. |
    <br/>

3. Create input parameter [JSON](templates/NP-EUS2-SAP00-INFRASTRUCTURE.json)
    <br/>*`Observe Naming Convention`*<br/>
    ```bash
    vi NP-EUS2-SAP00-INFRASTRUCTURE.json
    ```
    <br/>

4. Terraform
    1. Initialization
       ```bash
       terraform init  --backend-config backend                                        \
                       ../../../sap-hana/deploy/terraform/run/sap_landscape/
       ```

    2. Plan
       <br/>*`Observe Naming Convention`*<br/>
       ```bash
       terraform plan  --var-file=NP-EUS2-SAP00-INFRASTRUCTURE.json                     \
                       ../../../sap-hana/deploy/terraform/run/sap_landscape/
       ```

    3. Apply
       <br/>*`Observe Naming Convention`*<br/>
       ```bash
       terraform apply --auto-approve                                                  \
                       --var-file=NP-EUS2-SAP00-INFRASTRUCTURE.json                     \
                       ../../../sap-hana/deploy/terraform/run/sap_landscape/
       ```
       <br/>


<br/><br/><br/><br/>

# Next: [SAP Deployment Unit - SDU](06-sdu.md) <!-- omit in toc -->
