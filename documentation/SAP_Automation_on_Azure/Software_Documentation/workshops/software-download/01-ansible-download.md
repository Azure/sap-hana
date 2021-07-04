# ![SAP Deployment Automation Framework](../../../assets/images/UnicornSAPBlack64x64.png)**SAP Deployment Automation Framework** #

# Pre Deployment Configuration and Software Download <!-- omit in toc --> #

## Table of contents <!-- omit in toc --> ##

- [Overview](#overview)
- [Notes](#notes)
- [Procedure](#procedure)
  - [Configuring Azure KeyVault secrets](#configuring-azure-keyvault-secrets)
  - [SAP Software Download - Ansible](#sap-software-download---ansible)

## Overview ##

![Graphic]()
|                  |               |
| ---------------- | ------------- |
| Duration of Task | `130 minutes` |
| Steps            | `4`           |
| Runtime          | `110 minutes` |

This step will download the SAP software specified in the SAP Bill of Materials (BOM) file using the SAP credentials from the deployer KeyVault. The downloaded files will be stored in the sapbits storage account in the SAP Library.

## Notes ##

This step will leverage an Ansible playbool to download software from SAP, the download will require a S User account with software download permissions.

## Procedure ##

### Configuring Azure KeyVault secrets ###

<br>

1. Store the required secrets in deployer Key Vault.

    Secrets to be created/updated:

    | Name of Secret             | Value                                                  |
    | -------------------------- | ------------------------------------------------------ |
    | S-Username                 | S User Account                                         |
    | S-Password                 | Password of S User Account                             |
    | sapbits-access-key         | Access key for the SAP Library sapbits storage account |

### SAP Software Download - Ansible ###

<br>

1. From the SAP Deployment Workspace directory, create a new directory 'BOMS'.

    ```bash
    mkdir -p ~/Azure_SAP_Automated_Deployment/WORKSPACES/BOMS
    cd ~/Azure_SAP_Automated_Deployment/WORKSPACES/BOMS
    ```

2. Create the `sap-parameters.yaml` parameter file.

    ```bash
    vi sap-parameters.yaml
    ```

    Values to be updated:

    | Parameter                  | Value                                     |
    | -------------------------- | ----------------------------------------- |
    | bom_base_name              | S41909SPS03_v0003ms                       |
    | sapbits_location_base_path | https://<storage_account_FQDN>/sapbits    |
    | kv_uri                     | Name of Key Vault containing the secrets  |

3. Execute the Ansible Playbook.

    There are three ways to do this.

    1. Via the Validator Test Menu.

        ```bash
        ~/Azure_SAP_Automated_Deployment/sap-hana/deploy/ansible/validator_test_menu.sh
        ```

        ```bash
        1) BOM Validator
        2) BOM Downloader
        3) Quit
        Please select playbook: 
        ```

    2. (*Optional*) Execute the Ansible playbooks individulally via `ansible-playbook` command.

        ```bash
        ansible-playbook                                                                                   \
          --user        azureadm                                                                           \
          --private-key sshkey                                                                             \
          --extra-vars="@sap-parameters.yaml"                                                              \
          ~/Azure_SAP_Automated_Deployment/sap-hana/deploy/ansible/<playbook>
        ```

        Use the following playbooks in the command, as shown in the order below.
        - `playbook_bom_validator.yaml`
        - `playbook_bom_downloader.yaml`

    3. (*Optional*) Execute the Ansible playbooks sequentially via a single `ansible-playbook` command.

        ```bash
        ansible-playbook                                                                                   \
          --user        azureadm                                                                           \
          --private-key sshkey                                                                             \
          --extra-vars="@sap-parameters.yaml"                                                              \
          ~/Azure_SAP_Automated_Deployment/sap-hana/deploy/ansible/playbook_bom_validator.yaml             \
          ~/Azure_SAP_Automated_Deployment/sap-hana/deploy/ansible/playbook_bom_downloader.yaml            \
        ```
