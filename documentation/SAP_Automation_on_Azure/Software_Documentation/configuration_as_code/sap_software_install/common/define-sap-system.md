# SAP System Definition

This document describes the process to generate a configuration file for a particular SAP System.
This file will contain the configuration required for the deployment of a system, and will be stored inthe Ansible Inventory folder.

For each new SAP System deployed, a SAP System Configuration file must be generated.

## Prerequisites

- Deployer has been provisioned
- SAP Library has been provisioned and populated
- System Infrastructure has been provisioned from the Deployer

## Process

1. Log on to the Deployer VM, and navigate to the `ansible_config_files` directory in your SAP System directory, e.g.

   ```shell
   cd ~/Azure_SAP_Automated_Deployment/WORKSPACES/SAP_SYSTEM/<SAP_System_Deployment_Folder>/ansible_config_files
   ```

   Where `SAP_System_Deployment_Folder` is the System being deployed, e.g. `NP-CEUS-SAP0-X00`.

1. Using the editor of your choice, create a variables file called `sap-system-config.yml` with the following content:

   ```yml
   # BoM Processing variables
   sapbits_location_base_path: ""
   bom_base_name: ""
   target_media_location: "/usr/sap/install"

   # SAS Token for downloading Media
   sapbits_sas_token: ""

   # SAP Configuration for templates and install
   aas_hostname: ""
   aas_instance_number: ""
   app_sid: ""
   download_basket_dir: "{{ target_media_location }}/download_basket"
   hdb_hostname: ""
   hdb_instance_number: ""
   hdb_sid: ""
   pas_hostname: ""
   pas_instance_number: ""
   password_hana_system: ""
   password_master: ""
   sap_fqdn: ""
   sapadm_uid: 2100
   sapinst_gid: 2001
   sapsys_gid: 2000
   scs_hostname: ""
   scs_instance_number: ""
   sidadm_uid: 2000
   ```

1. In the `sap-system-config.yml` file, supply the values for the variables as per descriptions below, and save the file.

   | Variable                     | Description                                                                       |
   | ---------------------------- | --------------------------------------------------------------------------------- |
   | `sapbits_location_base_path` | URL for the `sapbits` container from the Azure Portal.                            |
   | `bom_base_name`              | Matching the BoM upload directory in the SAP Library, e.g. `S4HANA_2020_ISS_v001` |
   | `sapbits_sas_token`          | SAS Token for the SAP Library Storage Account from the Azure Portal, see below.   |
   | `aas_hostname`               | Hostname for the AAS VM                                                           |
   | `aas_instance_number`        | Instance number for the AAS Instance, e.g. `"12"`                                 |
   | `app_sid`                    | SID for the Application Tier, e.g. `"X00"`                                        |
   | `hdb_hostname`               | Hostname for the HDB VM                                                           |
   | `hdb_instance_number`        | Instance number for the HDB Instance, e.g. `"00"`                                 |
   | `hdb_sid`                    | SID for the SAP HANA Database, e.g. `"D00"`                                       |
   | `pas_hostname`               | Hostname for the PAS VM                                                           |
   | `pas_instance_number`        | Instance number for the PAS Instance, e.g. `"10"`                                 |
   | `password_hana_system`       | Password used for the SAP HANA System                                             |
   | `password_master`            | Master Password for the Application Instance installation                         |
   | `sap_fqdn`                   | FQDN for the SAP System                                                           |
   | `sapadm_uid`                 | User ID for the `sapadm` user, e.g. `2100`                                        |
   | `sapinst_gid`                | Group ID for the sapinst group, e.g. `2001`                                       |
   | `sapsys_gid`                 | Group ID for the sapinst group, e.g. `2000`                                       |
   | `scs_hostname`               | Hostname for the SCS VM                                                           |
   | `scs_instance_number`        | Instance number for the SCS Instance, e.g. `"00"`                                 |
   | `sidadm_uid`                 | User ID for the `<SID>adm` user, e.g. `2100`                                      |

1. Generate a SAS Token for Installation Media downloads:

   1. Navigate to the SAP Library Storage Account in the [Azure Portal](https://portal.azure.com).
   1. Select `Shared access signature` in the menu panel on the left.
   1. For `Allowed services` ensure only `Blob` is selected.
   1. For `Allowed resource types` ensure only `Object` is selected.
   1. For `Allowed permissions` ensure only `Read` is selected.
   1. Ensure `Enables deletion of versions` is not selected.
   1. Set a large enough time frame for the SAS token is set to allow downloads to complete.
   1. Click `Generate SAS and connection string`.
   1. Copy the SAS token, and set in the above `sap-system-config.yml` file.

## Follow on Process

- [BoM Processing](./process-bom.md)
