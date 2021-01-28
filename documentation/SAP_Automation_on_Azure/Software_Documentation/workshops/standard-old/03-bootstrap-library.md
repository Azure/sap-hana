### <img src="../../../../../../assets/images/UnicornSAPBlack256x256.png" width="64px"> SAP Deployment Automation Framework <!-- omit in toc -->
<br/><br/>

# Bootstrap - SAP Library <!-- omit in toc -->

<br/>

## Table of contents <!-- omit in toc -->

- [Overview](#overview)
- [Procedure](#procedure)

<br/>

## Overview

![Block3](assets/Block3.png)
|                  |              |
| ---------------- | ------------ |
| Duration of Task | `5 minutes`  |
| Steps            | `5`          |
| Runtime          | `1 minutes`  |

---

<br/><br/>

## Procedure

<br/>

1. Repository

    1. Checkout Branch
        ```bash
        cd  ~/Azure_SAP_Automated_Deployment/sap-hana
        git checkout feature/keyvault
        ```

    2. Verify Branch is at expected Revision: `173b8b522e4e5b932a614cf13a20a07e859e4329`
        ```bash
        git rev-parse HEAD
        ```

<br/>

2. Create Working Directory.
    ```bash
    mkdir -p ~/Azure_SAP_Automated_Deployment/WORKSPACES/SAP_LIBRARY/NP-EUS2-SAP_LIBRARY; cd $_
    ```

<br/>

3. Create input parameter [JSON](templates/NP-EUS2-SAP_LIBRARY.json)
    ```bash
    vi NP-EUS2-SAP_LIBRARY.json
    ```

<br/>

4. Terraform
    1. Initialization
       ```bash
       terraform init  ../../../sap-hana/deploy/terraform/bootstrap/sap_library/
       ```

    2. Plan
       ```bash
       terraform plan                                                                  \
                       --var-file=NP-EUS2-SAP_LIBRARY.json                             \
                       ../../../sap-hana/deploy/terraform/bootstrap/sap_library
       ```

    3. Apply
       <br/>
       *This step deploys the resources*
       ```bash
       terraform apply --auto-approve                                                  \
                       --var-file=NP-EUS2-SAP_LIBRARY.json                             \
                       ../../../sap-hana/deploy/terraform/bootstrap/sap_library/
       ```

<br/><br/><br/><br/>

# Next: [Reinitialize](04-reinitialize.md) <!-- omit in toc -->
