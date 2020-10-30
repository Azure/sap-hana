# HANA Template Generation

**_Note:_** Creating a Virtual Machine within Azure to use as your workstation will improve the speed when transferring the SAP media from a Storage Account.

## Prerequisites

1. An editor for working with the generated files.
1. HANA Media downloaded
1. SAP Library contains all media for HANA installation
1. SAP HANA infrastructure has been deployed
1. Workstation has connectivity to SAP HANA Infrastructure (e.g. SSH keys in place)
1. Prerequisite RPMs installed, See [SAP Note 2886607](https://launchpad.support.sap.com/#/notes/2886607)

## Inputs

In order to generate the installation templates for SAP HANA, you will need:

1. SAPCAR executable
1. SAP HANA infrastructure.

Any additional components are not required at this stage as they do not affect the template files generated.

## Process

1. On your workstation, locate the SAP HANA Installation Media from Phase 1b and make note of the path as `<HANA_MEDIA>`;
1. Update the permissions to make `SAPCAR` executable (SAPCAR version may change depending on your downloads):\
   `chmod +x <HANA_MEDIA>/SAPCAR_1311-80000935.EXE`
1. Make and change to a temporary directory:\
   `mkdir /tmp/hana_template; cd $_`
1. Extract the HANA Server files (HANA Server SAR file version may change depending on your downloads):

   ```text
   <HANA_MEDIA>/SAPCAR_1311-80000935.EXE
   -manifest SAP_HANA_DATABASE/SIGNATURE.SMF
   -xf <HANA_MEDIA>/IMDB_SERVER20_037_7-80002031.SAR
   ```

1. Use the extracted `hdblcm` tool to generate an empty install template and password file. **_Note:_** These two files (`<name>.params` and `<name>.params.xml`) will be used in the automated installation of the SAP HANA Database.

   The file name used in this command should reflect the `<stack_version>` (e.g. `HANA_2_00_052_v001`):

   `SAP_HANA_DATABASE/hdblcm --dump_configfile_template=HANA_2_00_052_v001.params`

1. Edit the `HANA_2_00_052_v001.params` file:
   1. Update `components` to `all`:\
      `components=all`
   1. Update `hostname` to `{{ ansible_hostname }}`:\
      `hostname={{ ansible_hostname }}`
   1. Update `sid` to `{{ db_sid | upper }}`:\
      `sid={{ db_sid | upper }}`
   1. Update `number` to `{{ db_instance_number }}`:\
      `number={{ db_instance_number }}`
1. Edit the `HANA_2_00_052_v001.params.xml` file, replacing the three asterisks (`***`) for each value with the ansible variables as below:

   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!-- Replace the 3 asterisks with the password -->
   <Passwords>
       <root_password><![CDATA[{{ db_root_password }}]]></root_password>
       <sapadm_password><![CDATA[{{ db_sapadm_password }}]]></sapadm_password>
       <master_password><![CDATA[{{ db_master_password }}]]></master_password>
       <sapadm_password><![CDATA[{{ db_sapadm_password }}]]></sapadm_password>
       <password><![CDATA[{{ db_password }}]]></password>
       <system_user_password><![CDATA[{{ db_system_user_password }}]]></system_user_password>
       <streaming_cluster_manager_password><![CDATA[{{ db_streaming_cluster_manager_password }}]]></streaming_cluster_manager_password>
       <ase_user_password><![CDATA[{{ db_ase_user_password }}]]></ase_user_password>
       <org_manager_password><![CDATA[{{ db_org_manager_password }}]]></org_manager_password>
   </Passwords>
   ```

1. Upload the generated template files to the SAP Library:
   1. In the Azure Portal navigate to the `sapbits` file share;
   1. Create a new `templates` directory under `sapbits` if it does not already exist;
   1. Click "Upload";
   1. In the panel on the right, click "Select a file";
   1. Navigate your workstation to the template generation directory `/tmp/hana_template`;
   1. Select the generated templates, e.g. `HANA_2_00_052_v001.params` and `HANA_2_00_052_v001.params.xml`;
   1. Click "Advanced" to show the advanced options, and enter `templates` for the Upload Directory;
   1. Click "Upload".

### Manual HANA Installation Using Template

1. Connect to target VM for HANA installation as `root` user
1. Ensure the `HANA_2_00_052_v001.params` and `HANA_2_00_052_v001.params.xml` files exist in `/tmp/hana_template`
1. Edit the `HANA_2_00_052_v001.params` file and replace variables:
   1. Update `components` to `all`
   1. Update `hostname` to `<hana-vm-hostname>` for example: `hostname=hd1-hanadb-vm`
   1. Update `sid` to `<HANA SID>` for example: `sid=HD1`
   1. Update `number` to `<Instance Number>` for example: `number=00`
1. Edit the `HANA_2_00_052_v001.params.xml` file, replacing the ansible variables with a suitable master password as below:

   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!-- Replace the ansible variables {{ }} with a password of minimum 8 characters -->
   <!-- Use the same password for each -->
   <Passwords>
       <root_password><![CDATA[ma$terPassw0rd]]></root_password>
       <sapadm_password><![CDATA[ma$terPassw0rd]]></sapadm_password>
       <master_password><![CDATA[ma$terPassw0rd]]></master_password>
       <sapadm_password><![CDATA[ma$terPassw0rd]]></sapadm_password>
       <password><![CDATA[ma$terPassw0rd]]></password>
       <system_user_password><![CDATA[ma$terPassw0rd]]></system_user_password>
       <streaming_cluster_manager_password><![CDATA[ma$terPassw0rd]]></streaming_cluster_manager_password>
       <ase_user_password><![CDATA[ma$terPassw0rd]]></ase_user_password>
       <org_manager_password><![CDATA[ma$terPassw0rd]]></org_manager_password>
   </Passwords>

1. Run the HANA installation:\
   `cat HANA_2_00_052_v001.params.xml | SAP_HANA_DATABASE/hdblcm --read_password_from_stdin=xml -b --configfile=HANA_2_00_052_v001.params`

## Results and Outputs

1. A completed `inifile.params` template uploaded to SAP library for SAP HANA install
1. A working HANA instance ready for use in [Preparing App tier inifile](../app/prepare-ini.md)
