# Ansible Development Guide

<br>

## Input Parameters - API and Defaults

[ansible-input-api.yaml](vars/ansible-input-api.yaml) is the file containing the complete list Ansible variable definitions and their defaults, as used.
<br>
- Variables should be defined here, with thier default values if appropriate.
- In-line documentation is supported, and annotations should be made.
- Required parameters should be passed in as input parameters, described in the next section.
- Default parameters may also be overridden by passing them as input parameters.

---



<br>
<br>
<br>

## Input Parameters

The file `sap-parameters.yaml` must be maintained in the `ansible_config_files` sub-directory of the SDU deployment working directory.

The format of the file is as follows (example):
```
---

sap_sid:                       X00
bom_base_name:                 HANA_2_00_055_v1
sapbits_location_base_path:    https://sapcontrollib.blob.core.windows.net/sapbits

...
```
It is encouraged to columnary align the parameters for readability.

---



<br>
<br>
<br>

## Call the Playbook Menu

From the `ansible_config_files` sub-directory of the SDU deployment working directory, execute the following command:
`~/Azure_SAP_Automated_Deployment/sap-hana/deploy/ansible/test_menu.sh`

```
1) Base OS Config            8) APP Install
2) SAP specific OS Config    9) WebDisp Install
3) BOM Processing           10) Pacemaker Setup
4) SCS Install              11) Pacemaker SCS Setup
5) HANA DB Install          12) Pacemaker HANA Setup
6) DB Load                  13) Quit
7) PAS Install
Please select playbook: 
```
This will present a menu for ease of playbook execution.
- The code currently has a few hardcoded parameters that need to be made into input parameters for the script.
  ```
        ansible-playbook                                                                                                \
          --inventory   X00_hosts.yml                                                                                   \
          --user        azureadm                                                                                        \
          --private-key sshkey                                                                                          \
          --extra-vars="@sap-parameters.yaml"                                                                           \
          ~/Azure_SAP_Automated_Deployment/sap-hana/deploy/ansible/${playbook}
  ```
  - `X00_hosts.yml` the SID (`X00`) should be a parameter.
  - `sshkey` is expected to be the private key from the KeyVault. This has to be retrieved manually. It would be nice to see this be automatically fetched by the deployer without exposing it.
  - `~/Azure_SAP_Automated_Deployment/sap-hana/deploy/ansible` the path to the playbook should be auto-sensed.

---



<br>
<br>
<br>

## Playbooks

Here you will find a list of the PLAYBOOKS for Ansible. This is not necessarily a complete list, and may be updated. This is to illustrate a modular design with playbooks geared to a discrete usage or outcome.

| Playbook                                | Purpose                            |
| --------------------------------------- | ---------------------------------- |
| playbook_01_os_base_config.yaml         | Base OS Configuration              |
| playbook_02_os_sap_specific_config.yaml | SAP Specific OS Configuration      |
| playbook_03_bom_processing.yaml         | Process the BOM<br>Download the files<br>Make available on all servers of the SID |
| playbook_04a_sap_scs_install.yaml       | SWPM - Install the SCS             |
| playbook_05a_hana_db_install.yaml       | HANA - Install DB                  |
| playbook_05a_hana_db_hsr.yaml           | HANA - Configure HSR               |
| playbook_06a_sap_dbload.yaml            | SWPM - Load the DB                 |
| playbook_06b_sap_pas_install.yaml       | SWPM - Install the PAS             |
| playbook_06c_sap_app_install.yaml       | SWPM - Install the APP             |
| playbook_06d_sap_web_install.yaml       | SWPM - Install the WebDisp         |
| playbook_07a_pacemaker.yaml             | Pacemaker - General Configuration  |
| playbook_07b_pacemaker_scs.yaml         | Pacemaker - Configuration for SCS  |
| playbook_07c_pacemaker_hana.yaml        | Pacemaker - Configuration for HANA |

---



<br>
<br>
<br>

## Task List

A living list of Tasks to Automate and their organization

[Task List](../../../documentation/SAP_Automation_on_Azure/Software_Documentation/configuration_as_code/tasks.md)

---



<br>
<br>
<br>

## Directory Structure

```
ansible
├── group_vars
├── roles
├── roles-os
├── roles-sap
├── roles-sap-os
└── vars
```

- `group_vars`: Legacy; May change with refactoring.
- `roles     `: Legacy;       











