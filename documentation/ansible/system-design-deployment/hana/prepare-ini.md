# HANA Template Generation

## Prerequisites

1. HANA Media downloaded

## Inputs

In order to generate the installation templates for SAP HANA, you will need:

1. SAPCAR executable
1. SAP HANA Server

Any additional components are not required at this stage as they do not affect the template files generated

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

1. Use the extracted `hdblcm` tool to generate an empty install template and password file using the Stack Version (e.g. `hana_sp05_v001`):\
  `SAP_HANA_DATABASE/hdblcm --dump_configfile_template=HANA_sp05_v001.params`
  **_Note:_** These two files will be used in the automated installation of the SAP HANA Database
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
   1. Click Upload
   1. In the panel on the right, click Select a file
   1. Navigate your workstation to the template generation directory `/tmp/hana_template`
   1. Select the generated templates, e.g. `hana_sp05_v001.params` and `hana_sp05_v001.paramas.xml`
   1. Click Advanced to show the advanced options, and enter `templates` for the Upload Directory
   1. Click Upload

## Results and Outputs

1. A completed `inifile.params` template uploaded to SAP library for SAP HANA install
