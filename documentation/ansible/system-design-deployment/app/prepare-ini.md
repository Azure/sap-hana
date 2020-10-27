# Generate application tier unattended installation parameter inifiles

## Prerequisites

- User must have a completed install of HANA DB and ASCS before you can generate a PAS/AAS inifile template
- Bootstrap infrastructure has been deployed
- Bootstrap infrastructure has been configured
  - Deployer has been configured with public IP address
  - SAP Library contains all media for the relevant applications
- SAP infrastructure has been deployed
  - Deployer has connectivity to SAP Infrastructure (e.g. SSH keys in place/available via key vault)
  - 128GB data disk attached and mounted to target SAP VM this process is documented on the [Microsoft Azure Website](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/attach-disk-portal)
  - Broweser connectivity between workstation and target SAP VM

## Inputs

- SAP Library to be prepared with the SAP Media

## Process

### Access SWPM

1. Connect to your target VM as the `root` user
1. On your target server, create a temporary directory to copy the SAP media to:\
`mkdir /tmp/app_templates`
1. Mount the `sapbits` Azure file share to your target VM. This process is documented on the [Microsoft Azure Website](https://docs.microsoft.com/en-us/azure/storage/files/storage-how-to-use-files-linux)
1. Copy the media from `sapbits/archives` to your temporay dir `/tmp/app_templates`:\
`cp /mnt/<sapbits fileshare path> /tmp/app_templates`
1. Update the permissions to make `SAPCAR` executable (SAPCAR version may change depending on your downloads):\
`chmod +x /tmp/app_templates/SAPCAR_1311-80000935.EXE`
1. Make and change to a temporary directory:\
`mkdir /tmp/app_templates; cd $_`
1. Ensure `/usr/sap/install/SWPM/`exists and extract `SWPM20SP07_0-80003424.SAR` via `SAPCAR.EXE` here(SAR file version may change depending on your downloads):\
`/tmp/app_templates/SAPCAR_1311-80000935.EXE -xf /tmp/app_templates/SWPM20SP07_0-80003424.SAR -R /usr/sap/SWPM/`
1. Ensure `/usr/sap/install/config` exists and contains the XML Stack file downloaded from the SAP Maintence Planner
1. Ensure `/usr/sap/downloads/` exists
1. Extract `SAPEXE_200-80004393.SAR` using `SAPCAR.EXE` to `/usr/sap/downloads/`:\
`/tmp/app_templates/SAPCAR_1311-80000935.EXE  -xf /tmp/app_templates/SAPCAR_1311-80000935.EXE SAPEXE_200-80004393.SAR -R /usr/sap/downloads/`
1. Extract `SAPHOSTAGENT49_49-20009394.SAR` using `SAPCAR.EXE` to `/usr/sap/downloads/`:\
`/tmp/app_templates/SAPCAR_1311-80000935.EXE  -xf /tmp/app_templates/SAPCAR_1311-80000935.EXE SAPHOSTAGENT49_49-20009394.SAR usr/sap/downloads/`.
1. Follow the instructions bellow to generate each ini template

### Generating unattended installation inifile for ASCS

This section covers the manual generation of the ABAP SAP Central Services (ASCS) unattended install file

In order to install SCS unattended, an inifile needs to be generated in order to pass all of the required parameters into the SWPM installer. Currently, the only way to generate a new one is to partially run through a manual install as per SAP Note [2230669 - System Provisioning Using a Parameter Input File](https://launchpad.support.sap.com/#/notes/2230669)
The following steps show how to manually begin the install of an ASCS instance in order to create an unattended file should it be needed.

1. On your ASCS Node connected as Root launch Software Provisioning Manager, shown in [Software Provision Manager input](#Example-Software-Provision-Manager-input)
1. Establish a connection to the ASCS node using a web browser
1. Launch the required URL to access SWPM shown in [Software Provision Manager output](#Example-Software-Provision-Manager-output)
1. Accept the security risk and authenticate with the systems ROOT user credentials
1. Navigate through the drop-down menu to the "ASCS Instance" relevant to your installation
1. Select the `Custom` Parameter Mode and click Next
1. The SAP system ID should be prepopulated with {SID} and SAP Mount Directory /sapmnt, Click Next
1. The FQDN should be prepopulated.  Ensure “Set FQDN for SAP system” is checked, and click Next
1. Enter and confirm a master password which will be used during the creation of the ASCS instance, and click Next. Note `The password of user DBUser may only consist of alphanumeric characters and the special characters #, $, @ and _. The first character must not be a digit or an underscore`
1. The password fields will be pre-populated based on the master password supplied. Set the s4hadm OS user ID to 2000 and the sapsys OS group ID to 2000, and click Next
1. When prompted to supply the path to the SAPEXE kernel file, specify a path of /usr/sap/downloads/ and click Next
1. Notice the package status is "Available" Click Next
1. Notice the SAP Host Agent installation file status is "Available" Click Next
1. Details for the sapadm OS user will be presented next.  It is recommended to leave the password as inherited from the master password, and enter in the OS user ID of 2100, and click Next
1. Ensure the correct instance number for the installation is set, and that the virtual host name for the instance has been set, Click Next
1. Leave the ABAP message server ports at the defaults of 3600 and 3900, Click Next
1. Do not select any additional components to install, Click Next
1. Check `Skip setting of security parameters` and Click Next
1. Select the checkbox “Yes, clean up operating system users” then Click Next
1. On the Parameter Summary Page take a copy of the inifile.params file which is located in the temporary SAP installation directory, located at /tmp/sapinst_instdir/S4HANA1809/CORE/HDB/INSTALL/HA/ABAP/ASCS/.  This can be used as the basis for unattended deployments.
1. Click Cancel in SWPM, as the install can now be performed via the unattended method
1. Copy and rename `inifile.params` to `sapbits/templates`:\
`cp /tmp/sapinst_instdir/S4HANA1909/CORE/HDB/INSTALL/DISTRIBUTED/ABAP/ASCS/inifile.params /mnt/<sapbits fileshare path>/templates/scs.inifile.params`

#### Example software provision manager input

```bash
root@sid-xxascs-0 ~]$ /usr/sap/install/SWPM/sapinst
SAPINST_XML_FILE=/usr/sap/install/config/MP_STACK_S4_1909_v001.xml
SAPINST_USE_HOSTNAME=<target vm hostname>
```

**_Note:_** The `SAPINST_XML_FILE` should be set to the XML Stack File path you created in the `Access SWPM` stage of the document
**_Note:_** `SAPINST_USE_HOSTNAME` should be set to the hostname of the vm you are running the installation from. This can be obtained by entering `hostname` into your console session

#### Example software provision manager output

```text
Connecting to the ASCS VM to launch
********************************************************************************
Open your browser and paste the following URL address to access the GUI
https://sid-s4ascs-vm.vxvpmhokrrduhgvfx1enk2e42f.ax.internal.cloudapp.net:4237/sapinst/docs/index.html
Logon users: [root]
********************************************************************************
```

### Generating unattended installation parameter inifile for PAS-AAS

This section covers the manual generation of the ABAP PAS/AAS Primary ApplicationServer/ Additional Application Server unattended install file.

:hand: To generate the PAS/AAS inifiles you must have a fully built HANA DB and ACSC. :hand:

1. The [Access SWPM](#Access-SWPM) steps will need to be completed on the target VM before you can accesss SWPM
1. Connect to the PAS Node as Root user and launch Software Provisioning Manager, shown in [Software Provision Manager input](#Example-Software-Provision-Manager-input). Ensure that you update <sap_component> to PAS/AAS
1. Launch the required URL to access SWPM shown in [Software Provision Manager output](#Example-Software-Provision-Manager-output)
1. Accept the security risk and authenticate with the systems ROOT user credentials
1. Navigate through the drop down menu to the "Primary Application Server Instance" relevant to your installation
1. On the Parameter Settings Screen Select "Custom" and Click Next
1. Ensure the Profile Directory is set to `/sapmnt/<SID>/profile/` and Click Next
1. Set the Message Server Port to 3611 and Click Next
1. Set the Master Password for All Users and Click Next
1. On the Software Package Browser Screen
1. Enter the Search Directory to `/usr/sap/install/config` then Click Next
1. ⌛️ ... wait several minutes for `below-the-fold-list` to populate then Click Next
1. Ensure the Upgrade SAP Host Agent to the version of the provided SAPHOSTAGENT.SAR archive option is unchecked then Click Next
1. Enter the Instance Number of the SAP HANA Database and Click Next
1. Set the Password of the SAP HANA Database Superuser to the Master Password and Click Next
1. Continue to the SLD Destination for the SAP System OS Level Screen. Ensure "No SLD destination" is selected and Click Next
1. Ensure Do not create Message Server Access Control List is selected and Click Next
1. Ensure Run TMS is selected
1. Set the Password of User TMSADM in Client 000 to the Master Password and Click Next
1. Set the SPAM/SAINT Update Archive to `/usr/sap/install/config/KD75371.SAR 1`
1. Select No for Import ABAP Transports
1. Click Next
1. On the Preparing for the Software Update Manager Screen
1. Ensure Extract the SUM*.SAR Archive is checked
1. Click Next
1. On the Software Package Browser Screen
1. Check the Detected Packages table
1. If the Individual Package Location for SUM 2.0 is empty
1. Set the Package Path above to `/usr/sap/install/config` and Click Next
1. Click Next
1. On the SAP System DDIC Users Screen
1. Click Next
1. On the Additional SAP System Languages Screen
1. Click Next
1. On the Secure Storage Key Generation Screen
1. Ensure Individual key is selected
1. Click Next
1. On the Warning Screen
1. Copy the Key ID and Key Value and store these securely
1. Click Ok
1. Ensure Yes, clean up operating system users is checked
1. Click Next
1. On the Parameter Summary Screen
1. On only the PAS/AAS node, take a copy of the `inifile.params` file which is located in the temporary SAP installation directory, located at /tmp/sapinst_instdir/S4HANA1809/CORE/HDB/INSTALL/HA/ABAP/ERS/.  This can be used as the basis for unattended deployments
1. Create a copy of the `inifile.params` to the `sapbits` Azure File Share to the `/templates/` directory and rename to `pas.inifile.params`:\
`cp /tmp/sapinst_instdir/S4HANA1909/CORE/HDB/INSTALL/DISTRIBUTED/ABAP/APP1/inifile.params /mnt/<sapbits fileshare path>/templates/pas.inifile.params`
1. For AAS:\
`cp /tmp/sapinst_instdir/S4HANA1909/CORE/HDB/INSTALL/AS/APPS/inifile.params inifile.params /mnt/<sapbits fileshare path>/templates/aas.inifile.params`

### Inifile consolidation

When you have completed generating your inifile.params templates you will need to consolidate the files into one inifile. Merge and deduplicate the files then Save the new file with a meaningful name relating to the SAP Product e.g `s4_1909_v2.inifile.params`.

1. Edit the `s4_1909_v2.inifile.params` file:
    1. Update `components` to `all`:\
        `components=all`
    1. Update `hostname` to `{{ ansible_hostname }}`:\
        `hostname={{ ansible_hostname }}`
    1. Update `sid` to `{{ app_sid | upper }}`:\
        `sid={{ app_sid | upper }}`
    1. Update `number` to `{{ app_instance_number }}`:\
        `number={{ app_instance_number }}`

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

1. A Consolidated `inifile.params` which can be used to the unattended installation of ASCS, PAS and AAS
1. Consildated inifile uploaded to `targets` directory in the `SAPBITS` Azure File Share
