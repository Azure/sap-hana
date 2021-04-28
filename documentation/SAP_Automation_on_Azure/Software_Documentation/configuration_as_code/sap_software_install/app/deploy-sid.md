# Application Deployment

## Prerequisites

1. Bootstrap infrastructure has been deployed;
1. Bootstrap infrastructure has been configured;
1. Deployer has been configured with working Ansible;
1. SAP Library contains all media for the relevant BoM;
1. SAP infrastructure has been deployed;
1. SAP Library contains all Terraform state files for the environment;
1. Deployer has Ansible connectivity to SAP Infrastructure (e.g. SSH keys in place/available via key vault);
1. Ansible inventory has been created.

## Inputs

1. BoM file;
1. Ansible inventory that details deployed SAP Infrastructure. **Note:** Inventory contents and format TBD, but may contain reference to the SAP Library;
1. SID (likely to exist in Ansible inventory in some form);
1. Unattended install template.

## Process

1. Log on to the Deployer VM, and navigate to the `ansible_config_files` directory in your SAP System directory, e.g.

   ```shell
   cd ~/Azure_SAP_Automated_Deployment/WORKSPACES/SAP_SYSTEM/NP-CEUS-SAP0-X00/ansible_config_files
   ```

1. Run Ansible playbooks which deploy SAP product components (using SWPM, or for SAP HANA hdblcm):

   __Note *:__ Commands marked below do not yet have automated playbooks covering their installation. For manual installation instructions see the Template Generation documentation

   1. Install the SCS:

      ```shell
      ansible-playbook -i hosts ~/Azure_SAP_Automated_Deployment/sap-hana/deploy/ansible/playbook_install_scs.yml
      ```

      The following illustrates an example of this process for deploying the SCS:

      ![Recording of SCS Deployment](../demos/scs_deployment.svg)


   1. If the HANA Database has not yet been installed, install the HANA Database \*:

      1. Ensure the mount point exists for the Installation Media:

         `mkdir -p /usr/sap/install`

      1. Ensure the exported Installation Media directory is mounted:

         `mount <scs-vm-IP>:/usr/sap/install /usr/sap/install`

      1. Make and change to a temporary directory:

         `mkdir /tmp/hana_install; cd $_`

      1. Ensure HDBLCM is available (adjust SERVER SAR filename to match your media):

         `/usr/sap/install/download_basket/SAPCAR.EXE -manifest SAP_HANA_DATABASE/SIGNATURE.SMF -xf /usr/sap/install/download_basket/IMDB_SERVER20_052_0-80002031.SAR`

      1. Update the HANA Installation template `/usr/sap/install/config/<BoM_Name>.params` file (where `BoM_Name` matches the HANA version to be installed, e.g. `HANA_2_00_052_v001`) and replace variables:
         1. Update `components` to `all`
         1. Update `hostname` to `<hana-vm-hostname>` for example: `hostname=hd1-hanadb-vm`
         1. Update `sid` to `<HANA SID>` for example: `sid=HD1`
         1. Update `number` to `<Instance Number>` for example: `number=00`

      1. Update the HANA Password file `/usr/sap/install/config/<BoM_Name>.params.xml` file, replacing all the ansible variables (e.g. `{{ db_root_password }}`) with a single suitable password for installation.

      1. Run the HANA installation:

         `cat /usr/sap/install/config/HANA_2_00_052_v001.params.xml | SAP_HANA_DATABASE/hdblcm --read_password_from_stdin=xml -b --configfile=/usr/sap/install/config/HANA_2_00_052_v001.params`

      :hand: The above commands will be moved into an Playbook as described below

      ```shell
      ansible-playbook -i hosts ~/Azure_SAP_Automated_Deployment/sap-hana/deploy/ansible/playbook_install_hana.yml
      ```

   1. Install the Database Content \*:

      ```shell
      ansible-playbook -i hosts ~/Azure_SAP_Automated_Deployment/sap-hana/deploy/ansible/playbook_install_db.yml
      ```

   1. Install the Primary Application Server \*:

      ```shell
      ansible-playbook -i hosts ~/Azure_SAP_Automated_Deployment/sap-hana/deploy/ansible/playbook_install_pas.yml
      ```

   1. Install the Additional Application Server(s) \*:

      ```shell
      ansible-playbook -i hosts ~/Azure_SAP_Automated_Deployment/sap-hana/deploy/ansible/playbook_install_aas.yml
      ```

   1. Install the Web Dispatcher Server(s) \*:

      ```shell
      ansible-playbook -i hosts ~/Azure_SAP_Automated_Deployment/sap-hana/deploy/ansible/playbook_install_web.yml
      ```

   Each of the above playbooks:

      1. Mounts the appropriate file shares from the SCS VM
      1. Configures OS groups and users using configurable gids/uids with viable defaults for greenfield systems
         1. `<SID>adm` user has the same UID across all systems using that SID
         1. `sapsys` group has same GID across all systems
         1. `sapadm` user has same UID across all systems
      1. Configures SAP OS prerequisites
         1. O/S dependencies (e.g. those found in SAP notes such as [2369910](https://launchpad.support.sap.com/#/notes/2369910))
         1. Software dependencies (e.g. those found in SAP notes such as [2365849](https://launchpad.support.sap.com/#/notes/2365849))
      1. Installs the SAP product via SWPM or hdblcm where appropriate

## Results and Outputs

1. SAP product has been deployed and running - ready to handle SAP client requests
1. Connection details/credentials so the Basis Administrator can configure any SAP clients
