### <img src="../../../assets/images/UnicornSAPBlack256x256.png" width="64px"> SAP Deployment Automation Framework <!-- omit in toc -->
<br/><br/>

# SDU - SAP Deployment Unit <!-- omit in toc -->

<br/>

## Table of contents <!-- omit in toc -->

- [Overview](#overview)
- [Notes](#notes)
- [Procedure](#procedure)
  - [SDU - SAP Deployment Unit](#sdu---sap-deployment-unit)


<br/>

## Overview

![Block5a](assets/Block5a.png)
![Block5b](assets/Block5b.png)
|                  |              |
| ---------------- | ------------ |
| Duration of Task | `5 minutes`  |
| Steps            | `6`          |
| Runtime          | `10 minutes`  |

---

<br/><br/>

## Notes

- For the workshop the *default* naming convention is referenced and used. For the **System** there are three fields.
  - `<ENV>`-`<REGION>`-`<SAP_VNET>`-`<SAP_SID>`

    | Field        | Legnth   | Value  |
    | ------------ | -------- | ------ |
    | `<ENV>`      | [5 CHAR] | DEMO     |
    | `<REGION>`   | [4 CHAR] | southcentralus   |
    | `<SAP_VNET>` | [7 CHAR] | SAP00  |
    | `<SAP_SID>`  | [3 CHAR] | X00    |
  
    Which becomes this: **DEMO-SCUS-SAP00-X00**
    
    This is used in several places:
    - The path of the Workspace Directory.
    - Input JSON file name
    - Resource Group Name.

    You will also see elements cascade into other places.

<br/><br/>

## Procedure

### SDU - SAP Deployment Unit

<br/>

1. Create Working Directory.
    <br/>*`Observe Naming Convention`*<br/>
    ```bash
    mkdir -p ~/Azure_SAP_Automated_Deployment/WORKSPACES/SYSTEM/DEMO-SCUS-SAP00-X00; cd $_
    ```
    <br/>

2. Create input parameter
    <br/>*`Observe Naming Convention`*<br/>
    ```bash
    mkdir -p ~/Azure_SAP_Automated_Deployment/WORKSPACES/SYSTEM/DEMO-SCUS-SAP00-X00; cd $_

    cat <<EOF > DEMO-SCUS-SAP00-X00.json
    {
      "infrastructure": {
        "environment"                         : "DEMO",
        "region"                              : "southcentralus",
        "vnets": {
          "sap": {
            "name"                            : "SAP00",
            "subnet_db": {
              "prefix"                        : "10.1.1.0/28"
            },
            "subnet_web": {
              "prefix"                        : "10.1.1.16/28"
            },
            "subnet_app": {
              "prefix"                        : "10.1.1.32/27"
            },
            "subnet_admin": {
              "prefix"                        : "10.1.1.64/27"
            }
          }
        }
      },
      "databases": [
        {
          "platform"                          : "HANA",
          "high_availability"                 : false,
          "size"                              : "S4Demo",
          "os": {
            "publisher"                       : "SUSE",
            "offer"                           : "sles-sap-12-sp5",
            "sku"                             : "gen1"
          }
        }
      ],
      "application": {
        "enable_deployment"                   : true,
        "sid"                                 : "X00",
        "scs_instance_number"                 : "00",
        "ers_instance_number"                 : "10",
        "scs_high_availability"               : false,
        "application_server_count"            : 3,
        "webdispatcher_count"                 : 1
      }
    }
    EOF
    ```

3. Deployment
   
     ```bash
     $DEPLOYMENT_REPO_PATH/deploy/scripts/installer.sh            \
     --parameterfile DEMO-SCUS-SAP00-X00.json                     \
     --type sap_system
     ```


<br/><br/><br/><br/>



<br/><br/><br/><br/>
