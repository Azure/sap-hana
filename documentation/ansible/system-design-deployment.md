# SAP System Design and Deployment

This document outlines a process that enables a SAP Basis System Administrator to produce repeatable baseline [SAP system landscapes](https://help.sap.com/doc/saphelp_afs64/6.4/en-US/de/6b0d84f34d11d3a6510000e835363f/content.htm) running in Azure.
The repeatability applies both across different SAP products _and_ over time, as new SAP software versions are released.
For example, an administrator may have a requirement to deploy a consistent [3-tier system landscape](https://help.sap.com/doc/saphelp_afs64/6.4/en-US/de/6b0da2f34d11d3a6510000e835363f/content.htm?no_cache=true) for S/4HANA 1909 SPS02 over the course of a few months, where Production is not required until 2-3 months after the Development system is required.
This can be a challenge when SAP removes available software versions, or a customer’s technical SAP personnel changes over time.

The process is aimed at users with some prior experience of both deploying SAP systems and with the Azure cloud platform.
For example, users should be familiar with: _SAP Launchpad_, _SAP Maintenance Planner_, _SAP Download Manager_, and _Azure Portal_.

The process described here consists of 3 distinct phases:

1. **_Acquisition_** of the SAP installation media, configuration files and tools;
1. **_Preparation_** of the SAP media library, and generation of the files required for automated deployments;
1. **_Deployment_** of the SAP landscape into Azure.

Two other phases are involved in the overall end-to-end lifecycle, but these are described elsewhere:

- **_Bootstrapping_** to deploy and configure the SAP Deployer and the SAP Library must be completed before _Preparation_;
- **_Provisioning_** to deploy the SAP target VMs into Azure must be completed before _Deployment_.

## Contents <!-- omit in toc -->

- [SAP System Design and Deployment](#sap-system-design-and-deployment)
  - [Phase 1: Acquisition](#phase-1-acquisition)
    - [Phase 1 Prerequisites](#phase-1-prerequisites)
    - [Phase 1 Inputs](#phase-1-inputs)
    - [Phase 1 Process](#phase-1-process)
      - [Phase 1a: The SAP Application](#phase-1a-the-sap-application)
      - [Phase 1b: The Database Software](#phase-1b-the-database-software)
    - [Phase 1 Results and Outputs](#phase-1-results-and-outputs)
  - [Phase 2: Preparation](#phase-2-preparation)
    - [Phase 2 Prerequisites](#phase-2-prerequisites)
    - [Phase 2 Inputs](#phase-2-inputs)
    - [Phase 2 Process](#phase-2-process)
      - [Example SAP Library file structure](#example-sap-library-file-structure)
      - [Example Bill of Materials (BoM) file](#example-bill-of-materials-bom-file)
    - [Phase 2 Results and Outputs](#phase-2-results-and-outputs)
  - [Phase 3: Installation of SAP System on Target VMs](#phase-3-installation-of-sap-system-on-target-vms)
    - [Phase 3 Prerequisites](#phase-3-prerequisites)
    - [Phase 3 Inputs](#phase-3-inputs)
    - [Phase 3 Process](#phase-3-process)
    - [Phase 3 Results and Outputs](#phase-3-results-and-outputs)

## Phase 1: Acquisition

### Phase 1 Prerequisites

- User must have an SAP account which has the correct permissions to download software and access Maintenance Planner
- User has [SAP Download Manager](https://softwaredownloads.sap.com/file/0030000001316872019) installed on their workstation

### Phase 1 Inputs

- SAP account login details (username, password)
- SAP System Product to deploy e.g. `S/4HANA`
- SAP Database configuration
- System name (SID)
- OS intended for use on HANA Infrastructure
- Language pack requirements

### Phase 1 Process

_**Note:** Creating a Virtual Machine within Azure to use as your workstation will improve the upload speed when transfering the SAP media to a Storage account.

Phase 1 is split into two parts, obtaining the Application Installation Media and stack files, and obtaining the Database Installation Media if required.

#### Phase 1a: The SAP Application

1. Create unique Stack Download Directory for SAP Downloads on User Workstation, e.g. `~/Downloads/S4HANA_1909_SP2/`
1. Log in to [SAP Launchpad](https://launchpad.support.sap.com/#)
1. Navigate to Software Downloads to clear the download basket
1. Log in to [Maintenance Planner](https://support.sap.com/en/alm/solution-manager/processes-72/maintenance-planner.html)
1. Design System, e.g. `S/4HANA`
1. Download Stack XML file to Stack Download Directory
1. Click `Push to Download Basket`
1. Download additional files (Stack Text File, PDF, Excel export)
1. Navigate to the Download Basket
1. Click the `T` icon above the table to download a file containing the URL hardlinks for the download basket and save to your workstation <sup>1</sup>
1. Run SAP Download Manager and login to access your SAP Download Basket
1. Set download directory to Stack Download Directory created in Phase 1a, step 1
1. Download all files into the empty DIR on workstation

#### Phase 1b: The Database Software

1. Create unique Stack Download Directory for SAP Downloads on User Workstation, e.g. `~/Downloads/HANA2.0/`
1. Log in to [SAP Launchpad](https://launchpad.support.sap.com/#)
1. Navigate to Software Downloads to clear the download basket
1. Find the SAP HANA Database media (Database and any additional components required) and add to download basket
1. Navigate to the Download Basket
1. Click the `T` icon above the table to download a file containing the URL hardlinks for the download basket and save to your workstation <sup>1</sup>
1. Run SAP Download Manager and login to access your SAP Download Basket
1. Set download directory to Stack Download Directory created in Phase 1b, step 1
1. Download all files into empty DIR on workstation

**Notes:**

1. The text file containing the download URL hardlinks is always named `myDownloadBasketFiles.txt` but is specific to the Application or Database and should be kept with the other downloads for the particular phase so it can be uploaded to the correct location in Phase 2.

### Phase 1 Results and Outputs

- XML Stack file
- Download Basket URL hardlinks file
- SAP Installation Media
- Stack Download Directory path containing Installation Media

## Phase 2: Preparation

### Phase 2 Prerequisites

- Acquisition process complete

### Phase 2 Inputs

- SAP XML Stack file stored on user’s workstation in the Stack Download Directory.
- SAP Media stored on user’s workstation in the Stack Download Directory.
- SAP Library.

### Phase 2 Process

1. Upload the downloaded media and stack files to the sapbits container in the Storage Account for the SAP Library, using the directory structure shown in the [Example SAP Library file structure](#example-sap-library-file-structure).
1. Create SAP Unattended Installation Template(s) (process TBD in Milestone 2).
1. Upload into SAP Library.
1. Create the BoM file.
1. Populate BoM with required inputs shown in the [Example Bill of Materials (BoM) file](#example-bill-of-materials-bom-file).
1. Upload BoM files to SAP Library.

#### Example SAP Library file structure

```text
sapbits
|
|-- archives/
|   |-- igshelper_17-1001245.sar
|   |-- KE60870.SAR
|   |-- KE60871.SAR
|   |-- <id>[.SAR|.sar]
|   |-- SAPCAR_1320-80000935.EXE
|   |-- <tool>_<id>.EXE
|
|-- BoMs/
|   |-- S4HANA2_SP05_v001/
|   |   |-- bom.yml
|   |   |-- stackfiles/
|   |   |   |-- MP_Excel_1001034051_20200921_SWC.xls
|   |   |   |-- MP_Plan_1001034051_20200921_.pdf
|   |   |   |-- MP_Stack_1001034051_20200921_.txt
|   |   |   |-- MP_Stack_1001034051_20200921_.xml
|   |   |   |-- myDownloadBasketFiles.txt
|   |
|   |-- BW4HANA_SP04_v001/
|   |   |-- ...
|   |
|   |-- BW4HANA_SP05_v002/
|       |-- ...
|
|-- templates/
    |-- s4_1909_v2.ini
    |-- hana2_sp05_v2.ini
```

**Notes:**

1. To prevent duplication, the Installation Media and Tools for all systems designed will be kept in a single flat `archives` directory.
1. The Bill of Materials directory (BoMs/) will contain a folder for each system the user designs. The recommended naming convention for these folders will use the product type(e.g. S4HANA), service pack version (e.g. SP05), and a version marker (e.g. v001). This allows the user to update a particular system BoM and retain an earlier version should it ever be needed.
1. The Bill of Materials file (bom.yml) and template files (hana.ini, application.ini) will be created following manual steps (process TBD in Milestone 2).
1. Additional SAP files obtained from SAP Maintenance Planner (the XML Stack file, Text file representation of stack file, the PDF and xls files) will be stored in a subfolder for a particular BoM.
1. Stack files are made unique by an index, e.g. `MP_<type>_<index>_<date>_<???>.<filetype>` where `<type>` is Stack, Plan, or Excel, `<index>` is a 10 digit integer, `<date>` is in format yyyymmdd, `<???>` is SWC for the Excel type and empty for the rest, and `<filetype>` is xls for type Excel, pdf for type Plan, and txt or xml for type Stack. . The text file containing the download URL hardlinks named `myDownloadBasketFiles.txt` is not unique, but specific to the BoM so should be stored in the BoM directory it relates to.

#### Example Bill of Materials (BoM) file

File `BoMs/S4HANA_SP05_v001/bom.yml`:

```yaml
---

name:    'S/4HANA - 1909'
version: 001
target:  'ABAP PLATFORM 1909'

ProductIdSCS:
ProductIdHDB:
ProductIdPAS:
ProductIdAPP:
ProductIdWEB:

materials:
  dependencies:
    - name:     HANA2
      version:  003

  media:
    - name:     SAPCAR
      version:  7.21
      archive:  SAPCAR_1320-80000935.EXE

    - name:     SWPM
      version:  2.0SP06
      archive:  SWPM20SP06_6-80003424.SAR

    - name:     SAP IGS HELPER
      version:  7.20EXT
      archive:  igshelper_17-10010245.sar

    - name:     SAP HR 6.08
      version:  608
      archive:  SAP_HR608.SAR

    - name:     S4COREOP 104
      version:  104
      archive:  S4COREOP104.SAR

  templates:
    - name:     SCS_INI
      version:  1909.2
      file:     scs_1909_v2.ini

    - name:     SCS_XML
      version:  1909.1
      file:     scs_1909_v2.xml
```

**Notes:**

1. The configuration for each individual HANA (or database) component will be stored in dependent BoMs, in order to allow for independent deployments when required.
2. The dependency with name `HANA2.0` and version `001` corresponds to the BoM file `BoMs/HANA2.0_v001/bom.yml` which would contain the actual SAP HANA version within the `materials.media` list.
3. Any `tools` or `media` materials with `.SAR` archives will be extracted
4. Any `tools` materials will be extracted with `0755` permissions
5. Any `media` materials will be extracted with `0644` permissions

### Phase 2 Results and Outputs

- SAP Media has been stored in SAP Library
- Consolidated SAP Unattended Install Template has been stored in SAP Library
- BoM has been stored in SAP Library
- SAP Library file path defined in Ansible inventory or passed in as a parameter to a playbook.

## Phase 3: Installation of SAP System on Target VMs

### Phase 3 Prerequisites

- Bootstrap infrastructure has been deployed
- Bootstrap infrastructure has been configured
  - Deployer has been configured with working Ansible
  - SAP Library contains all media for the relevant BoM
- SAP infrastructure has been deployed
  - SAP Library contains all Terraform state files for the environment
  - Deployer has Ansible connectivity to SAP Infrastructure (e.g. SSH keys in place/available via key vault)
  - Ansible inventory has been created

### Phase 3 Inputs

- Populated BoM file
- Ansible inventory that details deployed SAP Infrastructure
  - Note: Inventory contents and format TBD, but may contain reference to the SAP Library
- SID (likely to exist in Ansible inventory in some form)
- Unattended install template

### Phase 3 Process

1. Run Ansible playbook on SCS VM to configure base-level OS
1. Run Ansible playbook on SCS VM to configure OS groups and users
   1. Use defaulted gids/uids
1. Run Ansible playbook on SCS VM to configure SAP OS prerequisites
   1. Configure O/S dependencies (e.g. those found in SAP notes such as [2369910](https://launchpad.support.sap.com/#/notes/2369910))
   1. Configure software dependencies (e.g. those found in SAP notes such as [2365849](https://launchpad.support.sap.com/#/notes/2365849))
1. Run Ansible playbook on SCS VM to configure LVM
   1. Configure volumes
1. Run Ansible playbook on SCS VM to configure SAP mounts
   1. Configure directory structure (e.g. `/sapmnt`, `/usr/sap`, etc.)
   1. Configure file systems (i.e. `/etc/fstab`)
1. Run Ansible playbook on SCS VM to configure NFS and create/export media directory
   1. Configure install directories (e.g. `/sapmnt/<SID>` and `/usr/sap/install`)
   1. Configure media directory exports
1. Run Ansible playbook on SCS VM to unarchive SAP Media and extract to exported media directory
   1. Iterates over BoM content to extract (media, unattended install templates, etc.)
   1. Media will be downloaded to a known location on the filesystem of a particular VM and selectively extracted where it benefits the automated process.
1. Run Ansible playbook on SCS VM to deploy SAP product components (using SWPM)

### Phase 3 Results and Outputs

- SAP product has been deployed and running - ready to handle SAP client requests
- Connection details/credentials so the Basis Administrator can configure any SAP clients
