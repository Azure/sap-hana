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

- For the workshop the *default* naming convention is referenced and used. For the **Landscape** there are three fields.
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

Logon to the deployer using the ssh key downloaded in the previous step.
<br/>

1. Create Working Directory.
    <br/>*`Observe Naming Convention`*<br/>
    ```bash
    mkdir -p ~/Azure_SAP_Automated_Deployment/WORKSPACES/LANDSCAPE/NP-EUS2-SAP00-INFRASTRUCTURE; cd $_
    ```
    <br/>


2. Create input parameter 
    <br/>*`Observe Naming Convention`*<br/>
    ```bash
    mkdir -p ~/Azure_SAP_Automated_Deployment/WORKSPACES/LANDSCAPE/DEMO-SCUS-SAP00-INFRASTRUCTURE; cd $_

    cat <<EOF > DEMO-SCUS-SAP00-INFRASTRUCTURE.json
    {
      "infrastructure": {
        "environment"                         : "DEMO",
        "region"                              : "southcentralus",
        "vnets": {
          "sap": {
            "name"                            : "SAP00",
            "address_space"                   : "10.1.0.0/16"
          }
        }
      }
    }
    EOF
    ```

    ```bash
    mkdir -p ~/Azure_SAP_Automated_Deployment/WORKSPACES/LANDSCAPE/DEMO-WEEU-SAP00-INFRASTRUCTURE; cd $_

    cat <<EOF > DEMO-WEEU-SAP00-INFRASTRUCTURE.json
    {
      "infrastructure": {
        "environment"                         : "DEMO",
        "region"                              : "westeurope",
        "vnets": {
          "sap": {
            "name"                            : "SAP00",
            "address_space"                   : "10.1.0.0/16"
          }
        }
      }
    }
    EOF
    ```

<br/>

3. Deployment
    
    *User the deployment data from the previous step for storageaccountname and vault.*
    
 ```bash
     $DEPLOYMENT_REPO_PATH/deploy/scripts/install_workloadzone.sh            \
     --parameterfile DEMO-SCUS-SAP00-INFRASTRUCTURE.json                     \
     --deployer_tfstate_key DEMO-SCUS-DEP00-INFRASTRUCTURE.terraform.tfstate \
     --storageaccountname demoscustfstate###                                 \
     --deployer_environment DEMO                                             \
     --vault DEMOSCUSDEP00user###                                            \
 ```

For **westeurope** use

 *Use the deployment data from the previous step for storageaccountname and vault*
 
 
 ```bash
     $DEPLOYMENT_REPO_PATH/deploy/scripts/install_workloadzone.sh            \
     --parameterfile DEMO-WEEU-SAP00-INFRASTRUCTURE.json                     \
     --auto-approve
 ```

4. Deployment providing the SPN Details. In this option the deployment of the workload zone requires different deployment credentials

*Use the deployment data from the previous step for storageaccountname and vault.*

```bash
     subscription=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
     spn_id=yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy
     spn_secret=zzzzzzzzzzzzzzz                                          
     tenant_id=ttttttttt-tttt-tttt-tttt-ttttttttttt
     deployer_environment=DEMO

```

```bash
     $DEPLOYMENT_REPO_PATH/deploy/scripts/install_workloadzone.sh            \
     --parameterfile DEMO-SCUS-SAP00-INFRASTRUCTURE.json                     \
     --deployer_environment $deployer_environment                            \
     --subscription $subscription                                            \ 
     --spn_id $spn_id                                                        \
     --spn_secret "$spn_secret"                                              \
     --tenant_id $tenant_id                                                  \     
     --auto-approve
```


For **westeurope** use:


```bash
     $DEPLOYMENT_REPO_PATH/deploy/scripts/install_workloadzone.sh            \
     --parameterfile DEMO-WEEU-SAP00-INFRASTRUCTURE.json                     \
     --deployer_environment $deployer_environment                            \
     --subscription $subscription                                            \ 
     --spn_id $spn_id                                                        \
     --spn_secret "$spn_secret"                                              \
     --tenant_id $tenant_id                                                  \     
     --auto-approve
```

# Next: [SAP Deployment Unit - SDU](04-sdu.md) <!-- omit in toc -->
