# Application Media Acquisition

**_Note:_** Creating a Virtual Machine within Azure to use as your workstation will improve the upload speed when transferring the SAP media to a Storage account.

## Prerequisites

- User must have an SAP account which has the correct permissions to download software and access Maintenance Planner
- User has [SAP Download Manager](https://softwaredownloads.sap.com/file/0030000001316872019) installed on their workstation
- User has Java installed to run SAP Download Manager

## Inputs

- SAP account login details (username, password)
- SAP System Product to deploy e.g. `S/4HANA`
- SAP Database configuration
- System name (SID)
- OS intended for use on HANA Infrastructure
- Language pack requirements

## Process

1. Create unique Stack Download Directory for SAP Downloads on User Workstation, e.g. `~/Downloads/S4HANA_1909_SP2/`
1. Log in to [SAP Launchpad](https://launchpad.support.sap.com/#)
1. Navigate to Software Downloads to clear the download basket
   1. Click Download Basket in the bottom right corner
   1. Select all items
   1. Click the X above to table to remove any selected items from the Download Basket
1. Log in to [Maintenance Planner](https://support.sap.com/en/alm/solution-manager/processes-72/maintenance-planner.html)
1. Design System, e.g. `S/4HANA`
   1. Select Plan for SAP S/4HANA
   1. If desired, update the Maintenance Plan name in the top left.
   1. Ensure `Install New S4HANA System` is selected and click Next
   1. Enter SID for `Install a New System`
   1. Choose `Target Version`, e.g. `SAP S/4HANA 1909`
   1. Choose `Target Stack`, e.g. `02 (05/2020) FP`
   1. If required, choose Target Product Instances
   1. Click Next
   1. Select `Co-Deployed with Backend`
   1. Choose `Target Version`, e.g. `SAP FIORI FOR SAP S/4HANA 1909`
   1. Choose `Target Stack`, e.g. `02 (05/2020) FP`
   1. Click Next
   1. Click Continue Planning
   1. No changes required for a new system, Click Next
   1. For OS/DB dependent files, select `Linux on x86_64 64bit`
   1. Click Confirm
   1. Click Next
   1. If desired, NON-ABAP under `Select Stack Independent Files` can be expanded, and unrequired language files can be deselected
   1. Click Next
1. Download Stack XML file to Stack Download Directory
1. Click `Push to Download Basket`
1. Click `Additional Downloads`
   1. Click `Download Stack Text File`
   1. Click `Download PDF`
   1. Click `Export to Excel`
1. Navigate to the Download Basket
1. Click the `T` icon above the table to download a file containing the URL hardlinks for the download basket and save to your workstation <sup>1</sup>
1. Run SAP Download Manager and login to access your SAP Download Basket
1. Set download directory to Stack Download Directory created in Phase 1a, step 1
1. Download all files into the empty DIR on workstation

**_Note:_**

1. The text file containing the download URL hardlinks is always named `myDownloadBasketFiles.txt` but is specific to the Application or Database and should be kept with the other downloads for the particular phase so it can be uploaded to the correct location in Phase 2.

## Results and Outputs

- Application XML Stack file
- Application Download Basket URL hardlinks file
- Application Installation Media
- Stack Download Directory path containing Application Installation Media
