# Processing the Bill of Materials for SAP System Installation

The following illustrates an example of this process for processing the BoM:

![Recording of BoM Processing](../demos/bom_processing.svg)

## Prerequisites

- Deployer has been provisioned
- SAP Library has been provisioned and populated
- System Infrastructure has been provisioned from the Deployer
- The [SAP System configuration has been defined](./system-definition.md)

## Process

1. Log on to the Deployer VM, and navigate to the `ansible_config_files` directory in your SAP System directory, e.g.

   ```shell
   cd ~/Azure_SAP_Automated_Deployment/WORKSPACES/SAP_SYSTEM/<SAP_System_Deployment_Folder>/ansible_config_files
   ```

   Where `SAP_System_Deployment_Folder` is the System being deployed, e.g. `NP-CEUS-SAP0-X00`.

1. Run Ansible playbook which processes the BoM file to obtain and prepare the correct Installation Media for the system, and makes it available on the SCS node. Also exports the required fileshares for other nodes to install from.

   ```shell
   ansible-playbook -i hosts.yml ~/Azure_SAP_Automated_Deployment/sap-hana/deploy/ansible/playbook_process_bom.yml
   ```

   This playbook:

   1. Configures LVM volumes
   1. Configures generic SAP filesystem mounts
      1. Configures directory structure (e.g. `/sapmnt`, `/usr/sap`, etc.)
      1. Configures file systems (i.e. `/etc/fstab`)
   1. Configures install directories (e.g. `/sapmnt/<SID>` and `/usr/sap/install`)
   1. Iterates over BoM content to download (media, unattended install templates, etc.)
   1. **Note:** Nested BoMs will also be iterated over, to ensure media which may be needed for the installation will also be downloaded and made available.
   1. Downloads the Installation Media to a known location (`/usr/sap/install`) on the filesystem of a particular VM (SCS) and organised into directories where it benefits the automated process
   1. Creates NFS export of downloaded/extracted media making available to other VMs in the system

## Follow on Process

For ini file template generation:

- [HANA Template generation](../hana/prepare-ini.md)
- [Application Template Generation](../app/prepare-ini.md)

For SID deployment:

- [HANA Deployment](../hana/deploy-sid.md)
- [APP Deployment](../app/deploy-sid.md)
