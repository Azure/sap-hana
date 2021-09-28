### <img src="../../../assets/images/UnicornSAPBlack256x256.png" width="64px"> SAP Deployment Automation Framework <!-- omit in toc -->
<br/><br/>

# Prepare the region <!-- omit in toc -->

<br/>

## Table of contents <!-- omit in toc -->

- [Overview](#overview)
- [Notes](#notes)
- [Procedure](#procedure)
  - [Bootstrap - Deployer](#bootstrap---deployer)

<br/>

## Overview

![Block2](assets/Block2.png)
|                  |              |
| ---------------- | ------------ |
| Duration of Task | `12 minutes` |
| Steps            | `10`         |
| Runtime          | `5 minutes`  |

---

<br/><br/>

## Notes

- For the workshop the *default* naming convention is referenced and used. For the **Deployer** there are three fields.
  - `<ENV>`-`<REGION>`-`<DEPLOYER_VNET>`-INFRASTRUCTURE

    | Field             | Legnth   | Value  |
    | ----------------- | -------- | ------ |
    | `<ENV>`           | [5 CHAR] | DEMO     |
    | `<REGION>`        | [4 CHAR] | EUS2   |
    | `<DEPLOYER_VNET>` | [7 CHAR] | DEP00  |
  
    Which becomes this: **DEMO-EUS2-DEP00-INFRASTRUCTURE**
    
    This is used in several places:
    - The path of the Workspace Directory.
    - Input JSON file name
    - Resource Group Name.

    You will also see elements cascade into other places.

<br/><br/>

## Procedure

### Prepare - region

<br/>

1. Cloud Shell
   1. Log on to the [Azure Portal](https://portal.azure.com).
   2. Open the cloud shell.
      <br/>![Cloud Shell](assets/CloudShell1.png)
      <br/><br/>

2. Ensure that you are authenticated with the correct subscription. 
    ```bash
    az login
    az account list --output=table | grep -i true
    ```

    If not, then find and set the Default to the correct subscription.

    ```bash
    az account list --output=table
    az account set  --subscription XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
    ```
    <br/>

1. environment
    ```bash
    export DEPLOYMENT_REPO_PATH=~/Azure_SAP_Automated_Deployment/sap-hana
    export ARM_SUBSCRIPTION_ID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
    ```

2. Repository
   1. Clone the Repository and Checkout the branch.
        ```bash
        mkdir -p ~/Azure_SAP_Automated_Deployment; cd $_
        git clone https://github.com/Azure/sap-hana.git
        cd  ~/Azure_SAP_Automated_Deployment/sap-hana
        ```

    1. (*Optional*) Checkout Branch (beta branch is recommended)
        ```bash
        git checkout <branch_name>
        ```
        Do nothing if using **master** branch.<br/>
        Otherwise, use the appropriate
        - Tag         (*ex. v2.1.0-1*)
        - Branch Name (*ex. feature/remote-tfstate2*)
        - Commit Hash (*ex. 6d7539d02be007da769e97b6af6b3e511765d7f7*)
        <br/><br/>

    2. (*Optional*) Verify Branch is at expected Revision
        ```bash
        git rev-parse HEAD
        ```
        <br/>

4. DEPLOYER - Create Working Directory and prepare JSON.
    <br/>*`Observe Naming Convention` Choose a suitable location*<br/>
    ```bash
    mkdir -p ~/Azure_SAP_Automated_Deployment/WORKSPACES/DEPLOYER/DEMO-SCUS-DEP00-INFRASTRUCTURE; cd $_

    cat <<EOF > DEMO-SCUS-DEP00-INFRASTRUCTURE.json
    {
      "infrastructure": {
        "environment"                         : "DEMO",
        "region"                              : "southcentralus",
        "vnets": {
          "management": {
            "name"                            : "DEP00",
            "address_space"                   : "10.0.0.0/25",
            "subnet_mgmt": {
              "prefix"                        : "10.0.0.64/28"
            },
            "subnet_fw": {
              "prefix"                        : "10.0.0.0/26"
            }
          }
        }
      },
      "options": {
        "deployer_enable_public_ip"           : true
      },
      "firewall_deployment"                   : true,
      "enable_purge_control_for_keyvaults"    : false
    }
    EOF
    ```
    <br/>
    
    For a deployment to **westeurope** use this:

    ```bash
    mkdir -p ~/Azure_SAP_Automated_Deployment/WORKSPACES/DEPLOYER/DEMO-WEEU-DEP00-INFRASTRUCTURE; cd $_

    cat <<EOF > DEMO-WEEU-DEP00-INFRASTRUCTURE.json
    {
      "infrastructure": {
        "environment"                         : "DEMO",
        "region"                              : "westeurope",
        "vnets": {
          "management": {
            "name"                            : "DEP00",
            "address_space"                   : "10.0.0.0/25",
            "subnet_mgmt": {
              "prefix"                        : "10.0.0.64/28"
            },
            "subnet_fw": {
              "prefix"                        : "10.0.0.0/26"
            }
          }
        }
      },
      "options": {
        "deployer_enable_public_ip"           : true
      },
      "firewall_deployment"                   : true,
      "enable_purge_control_for_keyvaults"    : false
    }
    EOF
    ```


5. SAP_LIBRARY - Create Working Directory and prepare JSON.
    <br/>*`Observe Naming Convention` Use same location as for the deployer*<br/>
    ```bash
    mkdir -p ~/Azure_SAP_Automated_Deployment/WORKSPACES/LIBRARY/DEMO-SCUS-SAP_LIBRARY; cd $_

    cat <<EOF > DEMO-SCUS-SAP_LIBRARY.json
    {
      "infrastructure": {
      "environment"                           : "DEMO",
      "region"                                : "southcentralus"
      },
      "deployer": {
        "environment"                         : "DEMO",
        "region"                              : "southcentralus",
        "vnet"                                : "DEP00"
      }
    }
    EOF
    ```
    <br/>
    
    For a deployment to **westeurope** use this:
    
    ```bash
    mkdir -p ~/Azure_SAP_Automated_Deployment/WORKSPACES/LIBRARY/DEMO-WEEU-SAP_LIBRARY; cd $_

    cat <<EOF > DEMO-WEEU-SAP_LIBRARY.json
    {
      "infrastructure": {
      "environment"                           : "DEMO",
      "region"                                : "westeurope"
      },
      "deployer": {
        "environment"                         : "DEMO",
        "region"                              : "westeurope",
        "vnet"                                : "DEP00"
      }
    }
    EOF
    ```


6.  Prepare the environment
    1. Change to the WORKSPACES directory
    ```bash
    cd ~/Azure_SAP_Automated_Deployment/WORKSPACES
    ```
    <br/>

    2. Validate (optional)
    ```bash
    ${DEPLOYMENT_REPO_PATH}/deploy/scripts/validate.sh --parameterfile DEPLOYER/DEMO-SCUS-DEP00-INFRASTRUCTURE/DEMO-SCUS-DEP00-INFRASTRUCTURE.json \
                                                       --type sap_deployer

    ${DEPLOYMENT_REPO_PATH}/deploy/scripts/validate.sh --parameterfile LIBRARY/DEMO-SCUS-SAP_LIBRARY/DEMO-SCUS-SAP_LIBRARY.json \
                                                       --type sap_library
    ```

    <br/>
    
    For a deployment to **westeurope** use this:
    
    
    ```bash
    ${DEPLOYMENT_REPO_PATH}/deploy/scripts/validate.sh --parameterfile DEPLOYER/DEMO-WEEU-DEP00-INFRASTRUCTURE/DEMO-WEEU-DEP00-INFRASTRUCTURE.json \
                                                       --type sap_deployer

    ${DEPLOYMENT_REPO_PATH}/deploy/scripts/validate.sh --parameterfile LIBRARY/DEMO-WEEU-SAP_LIBRARY/DEMO-WEEU-SAP_LIBRARY.json \
                                                       --type sap_library
    ```

    3. Execute
    ```bash
    ${DEPLOYMENT_REPO_PATH}/deploy/scripts/prepare_region.sh                                                   \
        --deployer_parameter_file DEPLOYER/DEMO-SCUS-DEP00-INFRASTRUCTURE/DEMO-SCUS-DEP00-INFRASTRUCTURE.json  \
        --library_parameter_file LIBRARY/DEMO-SCUS-SAP_LIBRARY/DEMO-SCUS-SAP_LIBRARY.json                      \
        --auto-approve
    ```
    <br/>
    
    


    ```bash
    ${DEPLOYMENT_REPO_PATH}/deploy/scripts/prepare_region.sh                                                   \
        --deployer_parameter_file DEPLOYER/DEMO-WEEU-DEP00-INFRASTRUCTURE/DEMO-WEEU-DEP00-INFRASTRUCTURE.json  \
        --library_parameter_file LIBRARY/DEMO-WEEU-SAP_LIBRARY/DEMO-WEEU-SAP_LIBRARY.json                      \
        --auto-approve
    ```

    4. Answer Input
       1. Do you want to specify the SPN Details Y/N?
          - Environment name:
          - Keyvault name:
          - SPN App ID:
          - SPN App Password:
          - SPN Tenant ID:
          - SPN Subscription:

    
    Execute
    ```bash
    subscription=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    spn_id=yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy
    spn_secret=zzzzzzzzzzzzzzz                                          
    tenant_id=ttttttttt-tttt-tttt-tttt-ttttttttttt
 
    ${DEPLOYMENT_REPO_PATH}/deploy/scripts/prepare_region.sh                                                   \
        --deployer_parameter_file DEPLOYER/DEMO-SCUS-DEP00-INFRASTRUCTURE/DEMO-SCUS-DEP00-INFRASTRUCTURE.json  \
        --library_parameter_file LIBRARY/DEMO-SCUS-SAP_LIBRARY/DEMO-SCUS-SAP_LIBRARY.json                      \
        --subscription $subscription                                                                           \ 
        --spn_id $spn_id                                                                                       \
        --spn_secret "$spn_secret"                                                                             \
        --tenant_id $tenant_id                                                                                 \
        --auto-approve
    ```

For a deployment to **westeurope** use this:
    
        ```bash
    subscription=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    spn_id=yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy
    spn_secret=zzzzzzzzzzzzzzz                                          
    tenant_id=ttttttttt-tttt-tttt-tttt-ttttttttttt

    ${DEPLOYMENT_REPO_PATH}/deploy/scripts/prepare_region.sh                                                   \
        --deployer_parameter_file DEPLOYER/DEMO-WEEU-DEP00-INFRASTRUCTURE/DEMO-WEEU-DEP00-INFRASTRUCTURE.json  \
        --library_parameter_file LIBRARY/DEMO-WEEU-SAP_LIBRARY/DEMO-WEEU-SAP_LIBRARY.json                      \
        --subscription $subscription                                                                           \ 
        --spn_id $spn_id                                                                                       \
        --spn_secret "$spn_secret"                                                                             \
        --tenant_id $tenant_id                                                                                 \
        --auto-approve
    ```


7.  Post Processing
    1. In Output Section make note of the following 
       1. deployer_public_ip_address
       2. deployer_kv_user_name
       3. deployer_kv_prvt_name
       4. deployer_public_key_secret_name
       5. deployer_private_key_secret_name
      
          <br/>![Outputs](assets/Outputs-Deployer.png)
          <br/><br/>


    2. Extract SSH Keys
       1. Private Key
          <br/>*`Observe Naming Convention`*<br/>
          <br/>*`Update Vault name`*<br/>
          ```
          az keyvault secret show               \
            --vault-name DEMOSCUSDEP00userXXX   \
            --name DEMO-SCUS-DEP00-sshkey     | \
            jq -r .value > sshkey
          ```
          <br/>

          <br/>*`Observe Naming Convention`*<br/>
          <br/>*`Update Vault name`*<br/>
          ```
          az keyvault secret show               \
            --vault-name DEMOWEEUDEP00userXXX   \
            --name DEMO-WEEU-DEP00-sshkey     | \
            jq -r .value > sshkey
          ```
          <br/>



    3. Download the Private Key for use in your SSH Terminal Application
       <br/>![Download File](assets/CloudShell2.png)

       <br/><br/><br/><br/>


# Next: [Install workload zone](03-workload-zone.md) <!-- omit in toc -->
