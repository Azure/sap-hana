# Application Media Acquisition

**_Note:_** Creating a Virtual Machine within Azure to use as your workstation will improve the upload speed when transferring the SAP media to a Storage account.

## Prerequisites

1. User must have an SAP account which has the correct permissions to download software and access Maintenance Planner;
1. User has [SAP Download Manager](https://softwaredownloads.sap.com/file/0030000001316872019) installed on their workstation;
1. User has Java installed to run SAP Download Manager.

## Inputs

1. SAP account login details (username, password);
1. SAP System Product to deploy, e.g. `S/4HANA`;
1. System name (SID);
1. Language pack requirements.
1. OS intended for use on Application Infrastructure;

## Process

1. Create unique Stack Download Directory for SAP Downloads on User Workstation, e.g. `~/Downloads/S4HANA_1909_SP2/`.
1. Log in to [SAP Launchpad](https://launchpad.support.sap.com/#).
1. Navigate to Software Downloads to clear the download basket:
   1. Click Download Basket in the bottom right corner;
   1. Select all items;
   1. Click the X above the table to remove any selected items from the Download Basket.
1. Find the SAPCAR utility and add to download basket:
   1. Ensure the search type at the top of the screen is set to Downloads;
   1. Enter `SAPCAR` into the search bar and click the search button;
   1. Click the `SAPCAR` row with the latest version and `Maintenance Software Component`. The available downloads will be filtered for latest version of the SAPCAR utility;
   1. Ensure dropdown menu above the table is set to the correct OS type, e.g. `LINUX ON X86_64 64BIT`;
   1. Click the checkbox next to the SAPCAR executable filename;
   1. Click the Shopping Cart icon above the table to add to the download basket.

      ![Example latest SAPCAR](../images/sap-sapcar.png)

1. Log in to [Maintenance Planner](https://support.sap.com/en/alm/solution-manager/processes-72/maintenance-planner.html).
1. Design System, e.g. `S/4HANA`:
   1. Select Plan for SAP S/4HANA;
   1. If desired, update the Maintenance Plan name in the top left;
   1. Ensure `Install New S4HANA System` is selected and click Next;
   1. Enter SID for `Install a New System`;
   1. Choose `Target Version`, e.g. `SAP S/4HANA 2020`;
   1. Choose `Target Stack`, e.g. `Initial Shipment Stack`;
   1. If required, choose Target Product Instances;
   1. Click Next;
   1. Select `Co-Deployed with Backend`;
   1. Choose `Target Version`, e.g. `SAP FIORI FOR SAP S/4HANA 2020`;
   1. Choose `Target Stack`, e.g. `Initial Shipment Stack`;
   1. Click Next;
   1. Click Continue Planning;
   1. No changes required for a new system, Click Next;
   1. For OS/DB dependent files, select `Linux on x86_64 64bit`;
   1. Click `Confirm Selection`;
   1. Click Next;
   1. If desired, NON-ABAP under `Select Stack Independent Files` can be expanded, and unrequired language files can be deselected;
   1. Click Next.
1. Download Stack XML file to Stack Download Directory:
1. Click `Push to Download Basket`;
1. Click `Additional Downloads`;
   1. Click `Download Stack Text File`;
   1. Click `Download PDF`;
   1. Click `Export to Excel`.
1. Navigate to the Download Basket from SAP Launchpad (you may need to refresh the page to see the new basket contents).
1. Click the `T` icon above the table to download a file containing the URL hardlinks for the download basket and save to your workstation <sup>1</sup>.
1. From your workstation:
   1. Run SAP Download Manager and login to access your SAP Download Basket;
   1. Set download directory to Stack Download Directory created in Phase 1a, step 1;
   1. Download all files into the empty DIR on workstation.

**_Note:_**

1. The text file containing the download URL hardlinks is always named `myDownloadBasketFiles.txt` but is specific to the Application or Database and should be kept with the other downloads for the particular phase so it can be uploaded to the correct location in Phase 2.

## Results and Outputs

1. Application XML Stack file;
1. Application Download Basket URL hardlinks file;
1. Application Installation Media;
1. Stack Download Directory path containing Application Installation Media.
