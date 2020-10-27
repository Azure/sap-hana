# Application Deployment

## Prerequisites

- Bootstrap infrastructure has been deployed
- Bootstrap infrastructure has been configured
  - Deployer has been configured with working Ansible
  - SAP Library contains all media for the relevant BoM
- SAP infrastructure has been deployed
  - SAP Library contains all Terraform state files for the environment
  - Deployer has Ansible connectivity to SAP Infrastructure (e.g. SSH keys in place/available via key vault)
  - Ansible inventory has been created

## Inputs

- Populated BoM file
- Ansible inventory that details deployed SAP Infrastructure
  - Note: Inventory contents and format TBD, but may contain reference to the SAP Library
- SID (likely to exist in Ansible inventory in some form)
- Unattended install template

## Process

1. Run Ansible playbook which configures base-level OS
1. Run Ansible playbook which configures base-level SAP OS
   1. Configures OS groups and users using configurable gids/uids with viable defaults for greenfield systems
      1. `<SID>adm` user has the same uid across all systems using that SID
      1. `sapsys` user has same uid across all systems
      1. `sapadm` user has same uid across all systems
   1. Configures SAP OS prerequisites
      1. O/S dependencies (e.g. those found in SAP notes such as [2369910](https://launchpad.support.sap.com/#/notes/2369910))
      1. Software dependencies (e.g. those found in SAP notes such as [2365849](https://launchpad.support.sap.com/#/notes/2365849))
   1. Configures LVM volumes
   1. Configures generic SAP filesystem mounts
      1. Configure directory structure (e.g. `/sapmnt`, `/usr/sap`, etc.)
      1. Configure file systems (i.e. `/etc/fstab`)
1. Run Ansible playbook which processes the BoM file to obtain and prepare the correct Installation Media for the system
   1. Configure install directories (e.g. `/sapmnt/<SID>` and `/usr/sap/install`)
   1. Configure media directory exports
   1. Iterates over BoM content to download (media, unattended install templates, etc.)
   1. Media will be downloaded to a known location (`/usr/sap/install`) on the filesystem of a particular VM and selectively extracted and organised into directories where it benefits the automated process
   1. Creates NFS export of downloaded/extracted media making available to other VMs in the system
   1. Mounts above export on other VMs
1. Run Ansible playbook which deploys SAP product components (using SWPM)

## Results and Outputs

- SAP product has been deployed and running - ready to handle SAP client requests
- Connection details/credentials so the Basis Administrator can configure any SAP clients
