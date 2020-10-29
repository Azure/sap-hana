# HANA Template Generation

**_Note:_** Creating a Virtual Machine within Azure to use as your workstation will improve the speed when transferring the SAP media from a Storage Account.

## Prerequisites

1. HANA Media downloaded
1. SAP Library contains all media for HANA installation
1. SAP HANA infrastructure has been deployed
1. Workstation has connectivity to SAP HANA Infrastructure (e.g. SSH keys in place)
1. Ensure prerequisite RPMs exist, See [SAP Note 2886607](https://launchpad.support.sap.com/#/notes/2886607)

## Inputs

In order to generate the installation templates for SAP HANA, you will need:

1. SAPCAR executable
1. SAP HANA infrastructure.

Any additional components are not required at this stage as they do not affect the template files generated.

## Process

1. On your workstation, locate the SAP HANA Installation Media from Phase 1b, make note of the path as `<HANA_MEDIA>`
1. Update the permissions to make `SAPCAR` executable (SAPCAR version may change depending on your downloads):\
   `chmod +x <HANA_MEDIA>/SAPCAR_1311-80000935.EXE`
1. Make and change to a temporary directory:\
   `mkdir /tmp/hana_template; cd $_`
1. Extract the HANA Server files (HANA Server SAR file version may change depending on your downloads):

   ```shell
   <HANA_MEDIA>/SAPCAR_1311-80000935.EXE
   -manifest SAP_HANA_DATABASE/SIGNATURE.SMF
   -xf <HANA_MEDIA>/IMDB_SERVER20_037_7-80002031.SAR
   ```

1. Use the extracted `hdblcm` tool to generate an empty install template and password file using the Stack Version (e.g. `hana_sp05_v001`). **_Note:_** These two files will be used in the automated installation of the SAP HANA Database:

   `SAP_HANA_DATABASE/hdblcm --dump_configfile_template=HANA_sp05_v001.params`

1. Edit the `HANA_sp05_v001.params` file:
   1. Update `components` to `all`:\
      `components=all`
   1. Update `hostname` to `{{ ansible_hostname }}`:\
      `hostname={{ ansible_hostname }}`
   1. Update `sid` to `{{ db_sid | upper }}`:\
      `sid={{ db_sid | upper }}`
   1. Update `number` to `{{ db_instance_number }}`:\
      `number={{ db_instance_number }}`
1. Edit the `HANA_sp05_v001.params.xml` file, replacing the three asterisks (`***`) for each value with the ansible variables as below:

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
   1. In the Azure Portal navigate to the `sapbits` file share
   1. Create a new `templates` directory under `sapbits`
   1. Click "Upload"
   1. In the panel on the right, click "Select a file"
   1. Navigate your workstation to the template generation directory `/tmp/hana_template`
   1. Select the generated templates, e.g. `hana_sp05_v001.params` and `hana_sp05_v001.paramas.xml`
   1. Click "Advanced" to show the advanced options, and enter `templates` for the Upload Directory
   1. Click "Upload"

### Manual HANA Installation Using Template

1. Connect to target VM for HANA installation as `root` user
1. Follow the previously outlined [Process](#Process). In this instance "Workstation" is the SAP HANA Target VM.
1. Replace variables set in both inifiles
1. Edit the `HANA_sp05_v001.params` file:
   1. Update `components` to `all`
   1. Update `hostname` to `<hana-vm-hostname>` for example: `hostname=hd1-hanadb-vm`
   1. Update `sid` to `<HANA SID>` for example: `sid=HD1`
   1. Update `number` to `<Instance Number>` for example: `number=00`
1. Edit the `HANA_sp05_v001.params.xml` file, replacing the ansible variables with a password as below:

   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!-- Replace the ansible varibles {{ }} with the password of minimum 8 charchters -->
   <!-- Use the same password for each entery-->
   <Passwords>
       <root_password><![CDATA[masterpassw0rd]]></root_password>
       <sapadm_password><![CDATA[masterpassw0rd]]></sapadm_password>
       <master_password><![CDATA[masterpassw0rd]]></master_password>
       <sapadm_password><![CDATA[masterpassw0rd]]></sapadm_password>
       <password><![CDATA[masterpassw0rd]]></password>
       <system_user_password><![CDATA[masterpassw0rd]]></system_user_password>
       <streaming_cluster_manager_password><![CDATA[masterpassw0rd]]></streaming_cluster_manager_password>
       <ase_user_password><![CDATA[masterpassw0rd]]></ase_user_password>
       <org_manager_password><![CDATA[masterpassw0rd]]></org_manager_password>
   </Passwords>

1. Run the HANA installation:\
   `cat HANA_sp05_v001.params.xml | SAP_HANA_DATABASE/hdblcm --read_password_from_stdin=xml -b --configfile=HANA_sp05_v001.params`

## Results and Outputs

1. A completed `inifile.params` template uploaded to SAP library for SAP HANA install
1. A working HANA instance ready for use in [Preparing App tier inifile](../app/prepare-ini.md)
