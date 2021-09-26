### <img src="../../../assets/images/UnicornSAPBlack256x256.png" width="64px"> SAP Deployment Automation Framework <!-- omit in toc -->
<br/><br/>

# Post Deployment Configuration and Software Install <!-- omit in toc -->

<br/>

## Table of contents <!-- omit in toc -->

- [Overview](#overview)
- [Notes](#notes)
- [Procedure](#procedure)
  - [Post Deployment Configuration - Ansible](#post-deployment-configuration---ansible)

<br/>

## Overview

![Graphic]()
|                  |               |
| ---------------- | ------------- |
| Duration of Task | `130 minutes` |
| Steps            | `3`           |
| Runtime          | `110 minutes` |

<br/>

This Configuration as Code (CaC) tooling will perform several operations on the deployed resources.
- Base OS configuration
- SAP specific OS Configuration
- SAP Bill of Materials (BOM) processing - Software Download
- DB Install
- SAP Software Install
  - SCS Install
  - DB Load
  - Primary Application Server Install

Future Steps will include:
- Application Server Install
- Web Dispatcher Install
- SAPRouter
- Pacemaker DB / SCS

---

<br/><br/>

## Notes


<br/><br/>

## Procedure

### Post Deployment Configuration - Ansible
<br/>

1. From the SAP Deployment Workspace directory, change to the `DEMO-EUS2-SAP00-X00` directory.
    ```bash
    cd ~/Azure_SAP_Automated_Deployment/WORKSPACES/SYSTEM/DEMO-EUS2-SAP00-X00
    ```
    <br/><br/>

2. Update the `sap_parameters.yaml` parameter file.
    <br/>
    
    Values to be updated:

    | Parameter                  | Value                                  |
    | -------------------------- | -------------------------------------- |
    | bom_base_name              | S419009SPS03_v1                        |
    | sapbits_location_base_path | https://<storage_account_FQDN>/sapbits |
    | main_password            | MasterPass00                           |
    | sap_fqdn                   | sap.contoso.com                        |
    
    <br/>

    ```bash
    vi sap_parameters.yaml
    ```
    <br/>

    File: `sap-parameters.yaml`
    ```bash
    ---

    bom_base_name:                 S41909SPS03_v1
    sapbits_location_base_path:    https://<storage_account_FQDN>/sapbits
    main_password:                 MasterPass00
    sap_fqdn:                      sap.contoso.com


    # TERRAFORM CREATED
    sap_sid:                       X00
    kv_name:                        DEMOEUS2SAP00user298
    secret_prefix:                 DEMO-EUS2-SAP00
    scs_high_availability:         false
    db_high_availability:          false

    disks:
      - { host: 'x00dhdb00l0c75', LUN: 0,  type: 'sap'    }
      - { host: 'x00dhdb00l0c75', LUN: 10, type: 'data'   }
      - { host: 'x00dhdb00l0c75', LUN: 11, type: 'data'   }
      - { host: 'x00dhdb00l0c75', LUN: 12, type: 'data'   }
      - { host: 'x00dhdb00l0c75', LUN: 13, type: 'data'   }
      - { host: 'x00dhdb00l0c75', LUN: 20, type: 'log'    }
      - { host: 'x00dhdb00l0c75', LUN: 21, type: 'log'    }
      - { host: 'x00dhdb00l0c75', LUN: 22, type: 'log'    }
      - { host: 'x00dhdb00l0c75', LUN: 2,  type: 'backup' }
      - { host: 'x00app00lc75',   LUN: 0,  type: 'sap'    }
      - { host: 'x00app01lc75',   LUN: 0,  type: 'sap'    }
      - { host: 'x00app02lc75',   LUN: 0,  type: 'sap'    }
      - { host: 'x00scs00lc75',   LUN: 0,  type: 'sap'    }
      - { host: 'x00web00lc75',   LUN: 0,  type: 'sap'    }

    ...
    ```
    <br/>


3. Execute the Ansible Playbook. <br/>There are three ways to do this.


   1. Via the Test Menu.
        ```bash
        time ~/Azure_SAP_Automated_Deployment/sap-hana/deploy/ansible/test_menu.sh
        ```
        Note: Use  of the `time` command is optional. It is simply there to output the length of time of the execution.<br/>
              Ex: `real    1m7.984s`
        <br/><br/>
        Select the Menu option sequentially, in order, 1 - 7 or 13 for all.<br/>
        *Options 8 - 12 are not yet functional.*
        ```bash
        1) Base OS Config            8) APP Install
        2) SAP specific OS Config    9) WebDisp Install
        3) BOM Processing           10) Pacemaker Setup
        4) HANA DB Install          11) Pacemaker SCS Setup
        5) SCS Install              12) Pacemaker HANA Setup
        6) DB Load                  13) Install SAP (1-7)
        7) PAS Install              14) Quit
        Please select playbook: 
        ```
        <br/>

        ---
        <br/><br/>


    2. (*Optional*) Execute the Ansible playbooks individulally via `ansible-playbook` command.
        <br/>
        ```bash
        ansible-playbook                                                                                   \
          --inventory   X00_hosts.yaml                                                                     \
          --user        azureadm                                                                           \
          --private-key sshkey                                                                             \
          --extra-vars="@sap-parameters.yaml"                                                              \
          ~/Azure_SAP_Automated_Deployment/sap-hana/deploy/ansible/<playbook>
        ```
        Use the following playbooks in the command, as shown in the order below.
        - `playbook_01_os_base_config.yaml`
        - `playbook_02_os_sap_specific_config.yaml`
        - `playbook_03_bom_processing.yaml`
        - `playbook_04_00_00_hana_db_install.yaml`
        - `playbook_05_00_00_sap_scs_install.yaml`
        - `playbook_05_01_sap_dbload.yaml`
        - `playbook_05_02_sap_pas_install.yaml`
        <br/><br/>


    3. (*Optional*) Execute the Ansible playbooks sequentially via a single `ansible-playbook` command.
        ```bash
        ansible-playbook                                                                                   \
          --inventory   X00_hosts.yaml                                                                     \
          --user        azureadm                                                                           \
          --private-key sshkey                                                                             \
          --extra-vars="@sap-parameters.yaml"                                                              \
          ~/Azure_SAP_Automated_Deployment/sap-hana/deploy/ansible/playbook_01_os_base_config.yaml         \
          ~/Azure_SAP_Automated_Deployment/sap-hana/deploy/ansible/playbook_02_os_sap_specific_config.yaml \
          ~/Azure_SAP_Automated_Deployment/sap-hana/deploy/ansible/playbook_03_bom_processing.yaml         \
          ~/Azure_SAP_Automated_Deployment/sap-hana/deploy/ansible/playbook_04_00_00_hana_db_install.yaml  \
          ~/Azure_SAP_Automated_Deployment/sap-hana/deploy/ansible/playbook_05_00_00_sap_scs_install.yaml  \
          ~/Azure_SAP_Automated_Deployment/sap-hana/deploy/ansible/playbook_05_01_sap_dbload.yaml          \
          ~/Azure_SAP_Automated_Deployment/sap-hana/deploy/ansible/playbook_05_02_sap_pas_install.yaml
        ```

       <br/><br/><br/><br/>
