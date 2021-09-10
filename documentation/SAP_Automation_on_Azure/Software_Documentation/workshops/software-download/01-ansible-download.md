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

2. Add secrets to KeyVault.
   - Where `<Deployer-User_KV_name>` is the keyvault name.
   - Where `<S-Username>` is the S user account name
   - Where `<S-Password>` is the S user account's password
   - Where `<access-key>` is the access key for the storage account

```bash
    az keyvault secret set --name "S-Username" --vault-name "<Deployer-User_KV_name>" --value "<S-Username>";
    az keyvault secret set --name "S-Password" --vault-name "<Deployer-User_KV_name>" --value "<S-Password>";
    # If not populated
    az keyvault secret set --name "sapbits-access-key" --vault-name "<Deployer-User_KV_name>" --value "<access-key>";
```

### SAP Software Download - Ansible ###

<br>

1. From the SAP Deployment Workspace directory, create a new directory 'BOMS' and the sap-parameter.yaml file.

    ```bash
    mkdir -p ~/Azure_SAP_Automated_Deployment/WORKSPACES/BOMS; cd $_
    cat <<EOF > sap-parameters.yaml
    ---
    bom_base_name:               S41909SPS03_v0004ms
    sapbits_location_base_path:  https://<storage_account_FQDN>/sapbits
    kv_uri:                      
    ...
    EOF
    
 ```
    
2. Update the `sap-parameters.yaml` parameter file.

 ```bash
    vi sap-parameters.yaml
 ```

    Values to be updated:

    | Parameter                  | Value                                     |
    | -------------------------- | ----------------------------------------- |
    | bom_base_name              | S41909SPS03_v0004ms                       |
    | sapbits_location_base_path | https://<storage_account_FQDN>/sapbits    |
    | kv_uri                     | Name of Key Vault containing the secrets  |

4. Execute the Ansible Playbook.

    There are three ways to do this.

    1. Via the Validator Test Menu.

        ```bash
        ~/Azure_SAP_Automated_Deployment/sap-hana/deploy/ansible/validator_test_menu.sh
        ```

        ```bash
        1) BOM Downloader
        2) BOM Uploader
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
        - `playbook_bom_downloader.yaml`
        - `playbook_bom_uploader.yaml`

    3. (*Optional*) Execute the Ansible playbooks sequentially via a single `ansible-playbook` command.

        ```bash
        ansible-playbook                                                                                   \
          --user        azureadm                                                                           \
          --private-key sshkey                                                                             \
          --extra-vars="@sap-parameters.yaml"                                                              \
          ~/Azure_SAP_Automated_Deployment/sap-hana/deploy/ansible/playbook_bom_downloader.yaml            \
          ~/Azure_SAP_Automated_Deployment/sap-hana/deploy/ansible/playbook_bom_uploader.yaml              
        ```
