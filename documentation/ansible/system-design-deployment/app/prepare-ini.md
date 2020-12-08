# Application Template Generation

**_Note:_** Creating a Virtual Machine within Azure to use as your workstation will improve the speed when transferring the SAP media from a Storage Account.

## Prerequisites

1. An editor for working with the generated files;
1. [HANA DB Deployment](../hana/prepare-ini.md) must be completed before following this process;
1. The BoM file for this stack.
1. SAP Library contains all media for the relevant applications;
1. SAP infrastructure has been deployed;
1. Application servers should have swap space of greater than 256MB configured;
1. Workstation has connectivity to SAP Infrastructure (e.g. SSH keys in place);
1. Browser connectivity between workstation and target SAP VM.

## Inputs

1. SAP Library prepared with the SAP Media.
1. The BoM file for this stack.

## Process

### Ensure Installation Media And Required Tools Are Present

1. Connect to your target VM as the `root` user;
1. Set the root user password to a known value as this will be required to access SWPM;
1. Mount the `sapbits` container to your target VM. This process is documented on the [Microsoft Azure Website](https://docs.microsoft.com/en-us/azure/storage/blobs/storage-how-to-mount-container-linux);

   **Note:** The following instructions assume you have mounted the container as `/mnt/sapbits`.

1. Make and change to a temporary directory:

   `mkdir /tmp/workdir; cd $_`

1. Ensure `/tmp/app_template/` exists:

   `mkdir /tmp/app_template/`

1. Ensure `/usr/sap/install/` exists:

   `mkdir /usr/sap/install/`

1. Using the `media` entries in the BoM file, copy the required media from `sapbits` to `/usr/sap/install`:
   1. For each entry in `media`:

      `cp /mnt/sapbits/archive/<archive> /usr/sap/install`

      Where `<archive>` is the filename in the `archive:` property of the entry in the BoM.

      For example: `cp /mnt/sapbits/archive/SAPHOSTAGENT49_49-20009394.SAR /usr/sap/install`

1. Update the permissions to make `SAPCAR` executable (SAPCAR version may change depending on your downloads):

   `chmod +x /usr/sap/install/SAPCAR_1311-80000935.EXE`

1. Ensure `/usr/sap/install/SWPM/` exists:

   `mkdir -p /usr/sap/install/SWPM`

1. Extract `SWPM20SP07_0-80003424.SAR` via `SAPCAR.EXE`. For example:

   `/usr/sap/install/SAPCAR_1311-80000935.EXE -xf /usr/sap/install/SWPM20SP07_0-80003424.SAR -R /usr/sap/install/SWPM/`

1. Ensure `/usr/sap/install/config` exists and contains the XML Stack file downloaded from the SAP Maintenance Planner:

   `mkdir -p /usr/sap/install/config && cp /mnt/sapbits/boms/S4HANA_2020_ISS_v001/stackfiles/<MP stack file>.xml /usr/sap/install/config`

1. Follow the instructions below to generate each `inifile` template.

### Generating unattended installation `inifile` for ASCS

This section covers the manual generation of the ABAP SAP Central Services (ASCS) unattended install file

In order to install SCS unattended, an `inifile` needs to be generated in order to pass all of the required parameters into the SWPM installer. Currently, the only way to generate a new one is to partially run through a manual install as per SAP Note [2230669 - System Provisioning Using a Parameter Input File](https://launchpad.support.sap.com/#/notes/2230669).

The following steps show how to begin the manual install of an ASCS instance in order to create an unattended installation file.

**Note:** During the template generation process, you may need to confirm the change of ownership of files and permissions.

1. On your ASCS Node as the `root` user, launch Software Provisioning Manager, as shown in [Software Provision Manager input](#Example-Software-Provision-Manager-input);
1. Establish a connection to the ASCS node using a web browser;
1. Launch the required URL to access SWPM shown in [Software Provision Manager output](#Example-Software-Provision-Manager-output);
1. Accept the security risk and authenticate with the system's `root` user credentials;
1. Navigate through the drop-down menu "SAP S/4HANA Server 2020" > "SAP HANA Database" > "Installation" > "Application Server ABAP" > "Distributed System" > "ASCS Instance";
1. Select the `Custom` Parameter Mode and click "Next";
1. The SAP system ID should be prepopulated with {SID} and SAP Mount Directory /sapmnt, click "Next";
1. The FQDN should be prepopulated.  Ensure "Set FQDN for SAP system" is checked, and click "Next";
1. Enter and confirm a master password which will be used during the creation of the ASCS instance, and click "Next".

   **Note:** `The password of user DBUser may only consist of alphanumeric characters and the special characters #, $, @ and _. The first character must not be a digit or an underscore`.

1. The password fields will be pre-populated based on the master password supplied. Set the `<sid>adm` OS user ID to 2000 and the `sapsys` OS group ID to 2000, and click "Next";
1. When prompted to supply the path to the SAPEXE kernel file, specify a path of `/usr/sap/install/download_basket` and click "Next";
1. Notice the package status is "Available" click "Next";
1. Notice the SAP Host Agent installation file status is "Available" click "Next";
1. Details for the sapadm OS user will be presented next. It is recommended to leave the password as inherited from the master password, and enter in the OS user ID of 2100, and click "Next";
1. Ensure the correct instance number for the installation is set, and that the virtual host name for the instance has been set, click "Next";
1. Leave the ABAP message server ports at the defaults of 3600 and 3900, click "Next";
1. Do not select any additional components to install, click "Next";
1. Check `Skip setting of security parameters` and click "Next";
1. Select the checkbox "Yes, clean up operating system users" then click "Next";
1. Do not click "Next" on the Parameter Summary Page. At this point the installation configuration is stored in a file named `inifile.params` in the temporary SAP installation directory.
1. To locate the file, list the files in `/tmp/sapinst_instdir/`.
1. If the file `.lastInstallationLocation` exists, view the file contents and note the directory listed.
1. If a directory named for the product you are installing exists, e.g. `S4HANA2020`, navigate into the folders matching the product installation type, for example:

   `/tmp/sapinst_instdir/S4HANA2020/CORE/HDB/INSTALL/HA/ABAP/ASCS/`

1. Click "Cancel" in SWPM, as the SCS install can now be performed via the unattended method;
1. Copy and rename `inifile.params` to `scs.inifile.params` in `/tmp/app_template`:

`cp <path_to_inifile>/inifile.params /tmp/app_template/scs.2020.inifile.params`

#### Example software provision manager input

```bash
/usr/sap/install/SWPM/sapinst                                         \
SAPINST_XML_FILE=/usr/sap/install/config/MP_STACK_S4_2020_v001.xml    \
SAPINST_USE_HOSTNAME=<target vm hostname>
```

**_Note:_** The `SAPINST_XML_FILE` should be set to the XML Stack File path you created in the `Access SWPM` stage of the document.

**_Note:_** `SAPINST_USE_HOSTNAME` should be set to the hostname of the VM you are running the installation from. This can be obtained by entering `hostname` into your console session.

#### Example software provision manager output

```text
Connecting to the ASCS VM to launch
********************************************************************************
Open your browser and paste the following URL address to access the GUI
https://sid-s4ascs-vm.vxvpmhokrrduhgvfx1enk2e42f.ax.internal.cloudapp.net:4237/sapinst/docs/index.html
Logon users: [root]
********************************************************************************
```

#### Manual SCS Installation Using Template

1. Connect to the SCS VM as `root` User
1. Clear out and change to work directory:
   `rm -rf /tmp/workdir/*; cd /tmp/workdir`
1. Launch SCS Unattended install replacing `<target vm hostname>` with the SCS VM hostname:

     ```bash
    /usr/sap/install/SWPM/sapinst                                            \
      SAPINST_XML_FILE=/usr/sap/install/config/MP_STACK_S4_2020_v001.xml     \
      SAPINST_USE_HOSTNAME=<target vm hostname>                              \
      SAPINST_INPUT_PARAMETERS_URL=/tmp/app_template/scs.2020.inifile.params \
      SAPINST_EXECUTE_PRODUCT_ID=NW_ABAP_ASCS:S4HANA2020.CORE.HDB.ABAPHA     \
      SAPINST_START_GUI=false                                                \
      SAPINST_START_GUISERVER=false
    ```

### Exporting SAP FileSystems from SCS VM

To enable the installation of a distributed system, the Installation Media, Configuration Files, and SID System directory needs to be shared between the SCS and Application VMs.

Follow the [SAP instructions for Exporting directories via NFS for Linux](https://help.sap.com/viewer/e85af73ba3324e29834015d03d8eea84/CURRENT_VERSION/en-US/73297e14899f4dbb878e26d9359f8cf7.html).

The directories to be exported for this process are:

1. `/usr/sap/<SID>/SYS` - Where `<SID>` is replaced with the SID from Step 7 of the [Generating unattended installation parameter `inifile` for ASCS](#generating-unattended-installation-inifile-for-ascs)
1. `/usr/sap/install`
1. `/tmp/app_template`
1. `/sapmnt/<SID>/global`
1. `/sapmnt/<SID>/profile`

### Mounting SAP FileSystems on Application (PAS and AAS) VMs

1. On the Application VMs connected as `root` ensure the mount points exist:

   `mkdir -p /usr/sap/{downloads,install/config,<SID>/SYS} /tmp/app_template /sapmnt/<SID>/{global,profile}`

1. Ensure the exported directories are mounted:
   1. `mount <scs-vm-IP>:/usr/sap/install /usr/sap/install`
   1. `mount <scs-vm-IP>:/usr/sap/install/config /usr/sap/install/config`
   1. `mount <scs-vm-IP>:/usr/sap/<SID>/SYS /usr/sap/<SID>/SYS`
   1. `mount <scs-vm-IP>:/tmp/app_template /tmp/app_template`
   1. `mount <scs-vm-IP>:/sapmnt/<SID>/global /sapmnt/<SID>/global`
   1. `mount <scs-vm-IP>:/sapmnt/<SID>/profile /sapmnt/<SID>/profile`

### Database Content Load Prerequisites

The following requirements must be in place on the PAS DB VM before attempting the DB Content Load:

1. `<sid>adm` User must exist and must be a member of the `sapinst` group;
1. The user ID for `<sid>adm` must match the value provided to hdblcm (`2000` is used in this process);
1. The Directory `/sapmnt/<SID>/global/` must be accessible to SWPM `chown <sid>adm:sapsys /sapmnt/<SID>/global`;
1. `sapinst` group must exist.

### Generating unattended installation parameter `inifile` for Database Content Load

:hand: Both HANA and SCS instances must be installed, configured and online before completing the DB content load.

1. Make and change to a temporary directory:

   `sudo install -d -m 0777 <sid>adm -g sapinst "/tmp/db_workdir"; cd $_`

1. Launch SWPM with the following command:

    ```bash
    /usr/sap/install/SWPM/sapinst   \
    SAPINST_XML_FILE=/usr/sap/install/config/MP_STACK_S4_2020_v001.xml
    ```

1. Connect to the URL displayed from a browser session on your workstation
1. Accept the security risk and authenticate with the systems ROOT user credentials
1. Navigate through the drop-down menu to the "SAP S4/HANA Server 2020" > "SAP HANA Database" > "Installation" > "Application Server ABAP" > Distributed System > Database Instance"
Distributed System" , click on "Database Instance" and click "Next"
1. Select the `Custom` Parameter Mode and click "Next";
1. Notice the profile directory which the ASCS instance installation created `/usr/sap/<SID>/SYS/profile` then click "Next"
1. Enter in the ABAP message server port for the ASCS instance, which should be 36`<InstanceNumber>` for example: "3600" then click "Next"
1. Enter the Master Password to be used during the database content installation and click "Next"
1. Confirm the details for `<SID>adm` user and clik "Next".
1. Populate the SAP HANA Database Tenant fields:
   1. Database Host should be the HANA DB VM hostname which can be found by navigating to the resource in the Azure Portal
   1. Instance Number should contain the HANA instance number for example: `00`
   1. Enter the ID for the new database tenant, for example: `S4H`
   1. Leave the prepopulated DB System Admin password value
   1. click "Next"
1. Verify the connection details and click "OK"
1. Enter the System Database Administrator Password and click "Next"
1. Enter the path to the SAPEXE Kernel `/usr/sap/install/download_basket` and click "Next"
1. Notice the files are listed as available and click "Next"
1. Notice the SAPHOSTAGENT file is listed as available and click "Next"
1. Click "Next" on the SAP System Administrator password confirmation.
1. Notice all the CORE HANA DB Export files are listed as available and click "Next"
1. Click "Next" on the Database Schema page for schema `DBACOCKPIT`.
1. Click "Next" on the Database Schema page for schema `SAPHANADB`.
1. Click "Next" on the Secure Storage for Database Connection page.
1. Click "Next" on the SAP HANA Import Parameters page.
1. Enter the Password for the HANA DB `<sid>adm` user on the Database VM, click "Next"
1. Click "Next" on the SAP HANA Client Software Installation Path page.
1. Notice the SAP HANA CLIENT file is listed as available and click "Next"
1. Ensure “Yes, clean up operating system users” is checked and click "Next
1. Do not click "Next" on the Parameter Summary Page. At this point the installation configuration is stored in a file named `inifile.params` in the temporary SAP installation directory.
1. To locate the file, list the files in `/tmp/sapinst_instdir/`.
1. If the file `.lastInstallationLocation` exists, view the file contents and note the directory listed.
1. If a directory named for the product you are installing exists, e.g. `S4HANA2020`, navigate into the folders matching the product installation type, for example:

   `/tmp/sapinst_instdir/S4HANA2020/CORE/HDB/INSTALL/HA/ABAP/DB/`

1. Click "Cancel" in SWPM, as the DB Content Load can now be performed via the unattended method;
1. Copy and rename `inifile.params` to `db.2020.inifile.params` in `/tmp/app_template`:

`cp <path_to_inifile>/inifile.params /tmp/app_template/db.2020.inifile.params`

1. Check the version of SWPM's `sapinst` tool:

   `/usr/sap/install/SWPM/sapinst -version`

   ```text
   SAPinst build information:
   --------------------------
   Version:         749.0.85
   Build:           2027494
   Compile time:    Oct 15 2020 - 03:53:09
   Make type:       optU
   Codeline:        749_REL
   Platform:        linuxx86_64
   Kernel build:    749, patch 928, changelist 2026562
   SAP JRE build:   SAP Java Server VM (build 8.1.065 10.0.2+000, Jul 27 2020 17:26:10 - 81_REL - optU - linux amd64 - 6 - bas2:320007 (mixed mode))
   SAP JCo build:   3.0.20
   SL-UI version:   2.6.64
   SAP UI5 version: 1.60.30
   ```

1. If the Version is greater than `749.0.69`, as per [SAP Note 2393060](https://launchpad.support.sap.com/#/notes/2393060) also copy the `keydb.xml` and `instkey.pkey` files:

   `cp <path_to_inifile>/{keydb.xml,instkey.pkey} /tmp/app_template/`

#### Manual DB Content Load Using Template

1. Connect to the PAS VM as `root` User
1. Clear out and change to work directory:
   `rm -rf /tmp/db_workdir/*; cd /tmp/db_workdir`
1. Launch the DB Load process via SWPM:

      ```bash
      /usr/sap/install/SWPM/sapinst                                           \
      SAPINST_INPUT_PARAMETERS_URL=/tmp/app_templates/db.2020.inifile.params  \
      SAPINST_STACK_XML=/usr/sap/install/config/MP_STACK_S4_2020_v001.xml     \
      SAPINST_EXECUTE_PRODUCT_ID=NW_ABAP_DB:S4HANA2020.CORE.HDB.ABAP          \
      SAPINST_SKIP_DIALOGS=true                                               \
      SAPINST_START_GUI=false SAPINST_START_GUISERVER=false
      ```

### Generating unattended installation parameter `inifile` for Primary Application Server

This section covers the manual generation of the ABAP PAS (Primary Application Server) unattended install file.

:hand: To generate the PAS inifiles you must have a fully built HANA DB and ASCS.

_**Note:** Steps prefixed with * may not be encountered in 2020 versions of SAP Products._

1. Connect to the PAS
1. Make and change to a temporary directory:
   `sudo install -d -m 0777 <sid>adm -g sapinst "/tmp/pas_workdir"; cd $_`
1. The [Access SWPM](#Access-SWPM) steps will need to be completed on the target VM before you can access SWPM
1. Connect to the PAS Node as Root user and launch Software Provisioning Manager, shown in [Software Provision Manager input](#Example-Software-Provision-Manager-input). Ensure that you update <sap_component> to PAS
1. Launch the required URL to access SWPM shown in [Software Provision Manager output](#Example-Software-Provision-Manager-output)
1. Accept the security risk and authenticate with the systems ROOT user credentials
1. Navigate through the drop-down menu: "SAP S/4HANA Server 2020" > "SAP HANA Database" > "Installation" > "Application Server ABAP" > "Distributed System" > "Primary Application Server Instance"
1. On the Parameter Settings Screen Select "Custom" and click "Next"
1. Ensure the Profile Directory is set to `/sapmnt/<SID>/profile/` or  `/usr/sap/<SID>/SYS/profile` and click "Next"
1. Set the Message Server Port to `36nn` where `nn` is the ASCS Instance number, for example: `3600` and click "Next"
1. Set the Master Password for All Users and click "Next"
1. On the Software Package Browser Screen set the Search Directory to `/usr/sap/install/download_basket` then click "Next"
1. ⌛️ ... wait several minutes for `below-the-fold-list` to populate then click "Next"
1. Ensure the "Upgrade SAP Host Agent to the version of the provided SAPHOSTAGENT.SAR archive" option is unchecked then click "Next"
1. Enter the Instance Number of the SAP HANA Database and Database System Administrator Password and click "Next"
1. Click "Next" on Configuration of SAP liveCache with SAP HANA.
1. Click "Next" on Database Schema for schema `DBACOCKPIT`.
1. Click "Next" on Database Schema for schema `SAPHANADB`.
1. Click "Next" on Secure Storage for Database Connection.
1. Ensure the PAS Instance Number and PAS Instance Host are correctly set and click "Next"
1. Click "Next" on ABAP Message Server Ports.
1. Click "Next" on Configuration of Work Processes.
1. Click "Next" on ICM User Management for the SAP Web Dispatcher.
1. Continue to the SLD Destination for the SAP System OS Level Screen. Ensure "No SLD destination" is selected and click "Next"
1. Ensure Do not create Message Server Access Control List is selected and click "Next"
1. * Ensure Run TMS is selected
1. * Set the Password of User TMSADM in Client 000 to the Master Password and click "Next"
1. * Set the SPAM/SAINT Update Archive to `/usr/sap/install/config/KD75371.SAR`
1. * Select No for Import ABAP Transports and click "Next"
1. * On the Preparing for the Software Update Manager Screen ensure Extract the `SUM*.SAR` Archive is checked and click "Next"
1. * On the Software Package Browser Screen check the Detected Packages table. If the Individual Package Location for SUM 2.0 is empty set the Package Path above to `/usr/sap/install/config` and click "Next"
1. * After the package location has populated, click "Next"
1. * On the Additional SAP System Languages Screen click "Next"
1. Click "Next" on SAP System DDIC Users.
1. On the Secure Storage Key Generation Screen ensure Individual key is selected and click "Next"
1. On the Warning Screen copy the Key ID and Key Value and store these securely and click "Ok"
1. Ensure Yes, clean up operating system users is checked
1. click "Next"
1. On the PAS nodes, a copy of the `inifile.params` file is generated in the temporary SAP installation directory:
   1. PAS inifile path `/tmp/sapinst_instdir/S4HANA2020/CORE/HDB/INSTALL/DISTRIBUTED/ABAP/APP1/inifile.params`
1. Click "Cancel" in SWPM, as the PAS installation can now be performed via the unattended method;
1. Copy and rename `inifile.params` to `pas.2020.inifile.params` in `/tmp/app_template`:

`cp <path_to_inifile>/inifile.params /tmp/app_template/pas.2020.inifile.params`

1. The inifiles can be used as the basis for unattended deployments
1. Create a copy of the `inifile.params` to the `sapbits` container  to the `/templates/` directory and rename to `pas.inifile.params`:

   `cp /tmp/app_template/pas.inifile.params /mnt/<sapbits fileshare path>/templates/`

`cp <path_to_inifile>/inifile.params /tmp/app_template/pas.2020.inifile.params`

### Manual PAS Installation Using Template

1. Connect to PAS as `root` user
1. Clear out and change to work directory:
   `rm -rf /tmp/pas_workdir/*; cd /tmp/pas_workdir`
1. Launch PAS Unattended install replacing `<target vm hostname>` with the PAS VM hostname
1. For a PAS unattended install run the following:

    ```bash
    /usr/sap/install/SWPM/sapinst                                                                                         \
    SAPINST_XML_FILE=/usr/sap/install/config/MP_STACK_S4_2020_v001.xml                                                    \
    SAPINST_USE_HOSTNAME=<target vm hostname>                                                                             \
    SAPINST_EXECUTE_PRODUCT_ID=NW_ABAP_CI:S4HANA2020.CORE.HDB.ABAP                                                        \
    SAPINST_INPUT_PARAMETERS_URL=/tmp/app_template/pas.2020.inifile.params                                                     \
    SAPINST_START_GUI=false SAPINST_START_GUISERVER=false
    ```

### Generating unattended installation parameter `inifile` for Addtional Application Server

This section covers the manual generation of the ABAP AAS (Additional Application Server) unattended install file.
The inifile can be used for multiple installations, therefore this process will only be required to be completed once - irrespective of the number of AASes you wish to deploy.

:hand: To generate the AAS inifiles you must have a fully built HANA DB and ASCS.

_**Note:** Steps prefixed with * may not be encountered in 2020 versions of SAP Products._

1. Connect to the AAS VM
1. Ensure `sapinst` group exists `groupadd -g 2000 sapinst` then `sudo install -d -m 0777 <sid>adm -g sapinst "/tmp/aas_workdir"; cd $_`
1. The [Access SWPM](#Access-SWPM) steps will need to be completed on the target VM before you can access SWPM
1. Connect to the AAS Node as `root` user and launch Software Provisioning Manager, shown in [Software Provision Manager input](#Example-Software-Provision-Manager-input). Ensure that you update <sap_component> to AAS
1. Launch the required URL to access SWPM shown in [Software Provision Manager output](#Example-Software-Provision-Manager-output)
1. Accept the security risk and authenticate with the systems `root` user credentials
1. Navigate through the drop-down menu:
    1. For AAS, "SAP S/4HANA Server 2020" > "SAP HANA Database" > "Installation" > "Application Server ABAP" > "High-Availability System" > "Additional Application Server Instance"
1. On the Parameter Settings Screen, select "Custom" and click "Next"
1. Ensure the Profile Directory is set to `/sapmnt/<SID>/profile/` or  `/usr/sap/<SID>/SYS/profile` and click "Next"
1. Set the Message Server Port to `36nn` where `nn` is the ASCS Instance number and click "Next"
1. Set the Master Password for All Users and click "Next"
1. On the Software Package Browser Screen set the Search Directory to `/usr/sap/install/download_basket` then click "Next"
1. ⌛️ ... wait several minutes for `below-the-fold-list` to populate then click "Next"
1. Ensure the "Upgrade SAP Host Agent to the version of the provided SAPHOSTAGENT.SAR archive" option is unchecked then click "Next"
1. Enter the Instance Number of the SAP HANA Database and Database System Administrator Password and click "Next"
1. Click "Next" on Configuration of SAP liveCache with SAP HANA.
1. Click "Next" on Database Schema for schema `DBACOCKPIT`.
1. Click "Next" on Database Schema for schema `SAPHANADB`.
1. Click "Next" on Secure Storage for Database Connection.
1. Ensure the AAS Instance Number and AAS Instance Host are correctly set and click "Next"
1. Click "Next" on ABAP Message Server Ports.
1. Click "Next" on Configuration of Work Processes.
1. Click "Next" on ICM User Management for the SAP Web Dispatcher.
1. Continue to the SLD Destination for the SAP System OS Level Screen. Ensure "No SLD destination" is selected and click "Next"
1. Ensure Do not create Message Server Access Control List is selected and click "Next"
1. * Ensure Run TMS is selected
1. * Set the Password of User TMSADM in Client 000 to the Master Password and click "Next"
1. * Set the SPAM/SAINT Update Archive to `/usr/sap/install/config/KD75371.SAR`
1. * Select No for Import ABAP Transports and click "Next"
1. * On the Preparing for the Software Update Manager Screen ensure Extract the `SUM*.SAR` Archive is checked and click "Next"
1. * On the Software Package Browser Screen check the Detected Packages table. If the Individual Package Location for SUM 2.0 is empty set the Package Path above to `/usr/sap/install/config` and click "Next"
1. * After the package location has populated, click "Next"
1. * On the Additional SAP System Languages Screen click "Next"
1. Ensure Yes, clean up operating system users is checked
1. click "Next"
1. On the AAS nodes, a copy of the `inifile.params` file is generated in the temporary SAP installation directory:
   1. AAS inifile path `/tmp/sapinst_instdir/S4HANA2020/CORE/HDB/INSTALL/AS/APPS/inifile.params`
1. Click "Cancel" in SWPM, as the AAS installation can now be performed via the unattended method;
1. Copy and rename `inifile.params` to `aas.2020.inifile.params` in `/tmp/app_template`:

`cp <path_to_inifile>/inifile.params /tmp/app_template/aas.2020.inifile.params`

1. The inifiles can be used as the basis for unattended deployments
1. Create a copy of the `inifile.params` to the `sapbits` container  to the `/templates/` directory and rename to `aas.2020.inifile.params`:

   `cp /tmp/app_template/aas.2020.inifile.params /mnt/<sapbits fileshare path>/templates/`

### Manual AAS Installation Using Template

:hand: A PAS must exist before the AAS Installation is attempted.

1. Connect to the AAS VM as the `root` user
1. Clear out and change to work directory:
   `rm -rf /tmp/aas_workdir/*; cd /tmp/aas_workdir`
1. Launch AAS Unattended install replacing `<target vm hostname>` with the AAS VM hostname
1. For a AAS unattended install run the following:

    ```bash
    /usr/sap/install/SWPM/sapinst                                                                          \
    SAPINST_XML_FILE=/usr/sap/install/config/MP_STACK_S4_2020_v001.xml                                     \
    SAPINST_USE_HOSTNAME=<target vm hostname>                                                              \
    SAPINST_EXECUTE_PRODUCT_ID=NW_DI:S4HANA2020.CORE.HDB.PD                                                \
    SAPINST_INPUT_PARAMETERS_URL=/tmp/app_template/aas.2020.inifile.params                                      \
    SAPINST_START_GUI=false SAPINST_START_GUISERVER=false
    ```

### `inifile` consolidation

To use the inifiles during the installation process, they should be consolidated into one file.

The overall process is to download the files to your workstation, extract the uncommented key value pairs into a new file, organise for ease of reference later, update values to Ansible variables for use with automation.

The file should be saved with a meaningful name relating to the SAP Product, e.g `S4HANA_2020_ISS_v001.inifile.params` and uploaded to the Storage Account.

1. Download all `inifile.params` files to your workstation, and make a backup of each file.
1. In **your editor** open each file.
1. Create a new consolidation file named for the SAP Product, e.g. `S4HANA_2020_ISS_v001.inifile.params`.
1. From the SCS inifile, copy the header into the consolidated file and format for readability, e.g.

   ```ini
   #########################################################################################################################
   #                                                                                                                       #
   # Installation service 'SAP S/4HANA Server 2020 > SAP HANA Database > Installation                                      #
   #   > Application Server ABAP > Distributed System > ASCS Instance', product id 'NW_ABAP_ASCS:S4HANA2020.CORE.HDB.ABAP' #
   #                                                                                                                       #
   #########################################################################################################################
   ```

1. For each `inifile.params` file:
   1. Copy the product id line from the header and add to the consolidated header:

      ```ini
      #############################################################################################################################################
      #                                                                                                                                           #
      # Installation service 'SAP S/4HANA Server 2020 > SAP HANA Database > Installation                                                          #
      #   > Application Server ABAP > Distributed System > ASCS Instance', product id 'NW_ABAP_ASCS:S4HANA2020.CORE.HDB.ABAP'                     #
      #   > Application Server ABAP > Distributed System > Database Instance', product id 'NW_ABAP_DB:S4HANA2020.CORE.HDB.ABAP'                   #
      #   > Application Server ABAP > Distributed System > Primary Application Server Instance', product id 'NW_ABAP_CI:S4HANA2020.CORE.HDB.ABAP' #
      #   > Additional SAP System Instances > Additional Application Server Instance', product id 'NW_DI:S4HANA2020.CORE.HDB.PD'                  #
      #                                                                                                                                           #
      #############################################################################################################################################
      ```

   1. Copy the Product ID from the header and update the `bom.yml` `product_ids` section for the relevant file. For example for SCS:

      ```yaml
      product_ids:
        scs: "NW_ABAP_ASCS:S4HANA2020.CORE.HDB.ABAP"
        db:  ""
        pas: ""
        aas: ""
        web: ""
      ```

   1. Remove all commented and blank lines.
   1. Copy the remaining lines into the consolidation file.
1. In the consolidation file:
   1. To improve readability:
      1. Sort all lines not in the header, and remove any duplicated lines.
      1. Align all the equals signs:

         ```ini
         archives.downloadBasket                             = /usr/sap/install/download_basket
         HDB_Schema_Check_Dialogs.schemaName                 = SAPHANADB
         HDB_Schema_Check_Dialogs.schemaPassword             = MyDefaultPassw0rd
         HDB_Userstore.doNotResolveHostnames                 = x00dx0000l09d4
         ```

      1. Separate the lines by prefix, e.g. `NW_CI_Instance.*`, `NW_HDB_DB.*` etc.
   1. Update the following lines to use Ansible variables:
      1. `archives.downloadBasket                             = {{ download_basket_dir }}`
      1. `HDB_Schema_Check_Dialogs.schemaPassword             = {{ password_hana_system }}`
      1. `HDB_Userstore.doNotResolveHostnames                 = {{ hdb_hostname }}`
      1. `hostAgent.sapAdmPassword                            = {{ password_master }}`
      1. `NW_AS.instanceNumber                                = {{ aas_instance_number }}`
      1. `NW_checkMsgServer.abapMSPort                        = 36{{ scs_instance_number }}`
      1. `NW_CI_Instance.ascsVirtualHostname                  = {{ scs_hostname }}`
      1. `NW_CI_Instance.ciInstanceNumber                     = {{ pas_instance_number }}`
      1. `NW_CI_Instance.ciMSPort                             = 36{{ scs_instance_number }}`
      1. `NW_CI_Instance.ciVirtualHostname                    = {{ pas_hostname }}`
      1. `NW_CI_Instance.scsVirtualHostname                   = {{ scs_hostname }}`
      1. `NW_DI_Instance.virtualHostname                      = {{ aas_hostname }}`
      1. `NW_getFQDN.FQDN                                     = {{ sap_fqdn }}`
      1. `NW_GetMasterPassword.masterPwd                      = {{ password_master }}`
      1. `NW_GetSidNoProfiles.sid                             = {{ app_sid | upper }}`
      1. `NW_HDB_DB.abapSchemaPassword                        = {{ password_master }}`
      1. `NW_HDB_getDBInfo.dbhost                             = {{ hdb_hostname }}`
      1. `NW_HDB_getDBInfo.dbsid                              = {{ hdb_sid | upper }}`
      1. `NW_HDB_getDBInfo.instanceNumber                     = {{ hdb_instance_number }}`
      1. `NW_HDB_getDBInfo.systemDbPassword                   = {{ password_hana_system }}`
      1. `NW_HDB_getDBInfo.systemid                           = {{ hdb_sid | upper }}`
      1. `NW_HDB_getDBInfo.systemPassword                     = {{ password_hana_system }}`
      1. `NW_readProfileDir.profileDir                        = /usr/sap/{{ app_sid | upper }}/SYS/profile`
      1. `NW_Recovery_Install_HDB.extractLocation             = /usr/sap/{{ hdb_sid | upper }}/HDB{{ hdb_instance_number }}/backup/data/DB_{{ hdb_sid | upper }}`
      1. `NW_Recovery_Install_HDB.sidAdmName                  = {{ hdb_sid | lower }}adm`
      1. `NW_Recovery_Install_HDB.sidAdmPassword              = {{ password_master }}`
      1. `NW_SAPCrypto.SAPCryptoFile                          = {{ download_basket_dir }}/SAPEXE_300-80004393.SAR`
      1. `NW_SCS_Instance.instanceNumber                      = {{ scs_instance_number }}`
      1. `NW_Unpack.igsExeSar                                 = {{ download_basket_dir }}/igsexe_12-80003187.sar`
      1. `NW_Unpack.igsHelperSar                              = {{ download_basket_dir }}/igshelper_17-10010245.sar`
      1. `NW_Unpack.sapExeDbSar                               = {{ download_basket_dir }}/SAPEXEDB_300-80004392.SAR`
      1. `NW_Unpack.sapExeSar                                 = {{ download_basket_dir }}/SAPEXE_300-80004393.SAR`
      1. `NW_SCS_Instance.scsVirtualHostname                  = {{ scs_hostname }}`
      1. `nwUsers.sapadmUID                                   = {{ sapadm_uid }}`
      1. `nwUsers.sapsysGID                                   = {{ sapsys_gid }}`
      1. `nwUsers.sidadmPassword                              = {{ password_master }}`
      1. `nwUsers.sidAdmUID                                   = {{ sidadm_uid }}`
      1. `storageBasedCopy.hdb.instanceNumber                 = {{ hdb_instance_number }}`
      1. `storageBasedCopy.hdb.systemPassword                 = {{ password_hana_system }}`

1. Upload the consolidated template file to the SAP Library:
    1. In the Azure Portal navigate to the `sapbits` container
    1. Click "Upload"
    1. In the panel on the right, click Select a file
    1. Select the generated template, e.g. `S4HANA_2020_ISS_v001.inifile.params`
    1. Click "Upload"
    1. Click "Advanced" to show the advanced options, and enter `templates` for the Upload Directory

1. Upload the updated BoM file to the SAP Library:
    1. In the Azure Portal navigate to the `sapbits` container
    1. Navigate to the product folder for the BoM, e.g. `boms/S4HANA_2020_ISS_v001`
    1. Click "Upload"
    1. In the panel on the right, click Select a file
    1. Select the updated `bom.yml`
    1. Click "Upload"

## Results and Outputs

1. A Consolidated `inifile.params` which can be used for the unattended installation of ASCS, PAS and AAS
1. Consolidated inifile uploaded to `templates` directory in the `sapbits` container
1. BoM file updated to contain the Product IDs and uploaded to the `sapbits` container
