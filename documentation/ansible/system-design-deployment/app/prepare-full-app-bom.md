# Application BoM Preparation

## Prerequisites

1. A Linux, MAC or Windows based workstation with the [`postman`](https://www.postman.com/downloads/) utility.
1. An editor for creating the SAP Application BoM file.
1. Application installation template(s) for SCS and/or PAS/AAS.
1. SAP Application media present on the Storage Account.
1. You have completed the downloading of associated stack files to your workstation's `stackfiles` folder.
1. An empty folder in which to create the BoM file.

## Inputs

1. Stack files.

## Process

1. Download the associated stack files to your workstation's empty, working folder;
1. Create an empty text file called `bom.yml`.

   ```text
   .
   ├── bom.yml      <-- BoM content will go in here
   ├── MP_Excel_xxx.xls
   ├── MP_Plan_xxx.pdf
   ├── MP_Stack_xxx.txt
   ├── MP_Stack_xxx.xml
   └── myDownloadBasketFiles.txt
   ```

### Get the SAP Download Basket Manifest

Ensure you do this section **before** running SAP Download Manager.

1. Start the `postman` utility and create a new `GET` request by clicking the :heavy_plus_sign: in the workspace tab.

   ![Postman New Request](../images/postman-new-request.png)

1. Ensure `GET` is selected and enter the request URL as `https://tech.support.sap.com:443/odata/svt/swdcuisrv/DownloadContentSet?_MODE=BASKET_CONTENT&_VERSION=3.1.2&$format=json`

   ![Postman Set Request URL](../images/postman-set-request-url.png)

1. Select the `Authorization` tab and choose `TYPE` as `Basic Auth` and enter your SAP user name and password in the appropriate fields.

   ![Postman Configure Basic Auth](../images/postman-basic-auth.png)

1. Click the blue `Send` button.

1. Copy the Raw JSON response body and save it in `DownloadBasket.json` in the `stackfiles/` folder on your workstation.

   ![Postman Save Raw JSON](../images/postman-save-raw-json.png)

1. Within the `S4HANA_1909_SP2_v001` folder, create an empty text file called `bom.yml`.

   ```text
   .
   ├── bom.yml      <-- BoM content will go in here
   ├── DownloadBasket.json
   ├── MP_Excel_xxx.xls
   ├── MP_Plan_xxx.pdf
   ├── MP_Stack_xxx.txt
   ├── MP_Stack_xxx.xml
   └── myDownloadBasketFiles.txt
   ```

### Example Partial BoM File

An example of a small part of a BoM file for S/4HANA 1909 SP2. The `[x]` numbered sections are covered in the following documentation. Note that `v001` is a sequential number used to indicate the internal (non-SAP) version of the files included.

```text
step|BoM Content
    |
    |---
    |
[1] |name:    'S4HANA_1909_SP2_v001'
[2] |target:  'ABAP PLATFORM 1909'
[3] |version: 001
    |
[4] |defaults:
    |  archive_location: "https://npweeusaplib9545.file.core.windows.net/sapbits/archives/"
    |  target_location: "/usr/sap/install/downloads/"
    |
[5] |materials:
[6] |  dependencies:
    |    - name:     HANA2
    |      version:  003
    |
[7] |  media:
    |    - name:     SAPCAR
    |      version:  7.21
    |      archive:  SAPCAR_1320-80000935.EXE
    |
    |    - name:     SWPM
    |      version:  2.0SP06
    |      archive:  SWPM20SP06_6-80003424.SAR
    |
    |    - name:     SAP IGS HELPER
    |      version:  7.20EXT
    |      archive:  igshelper_17-10010245.sar
    |
    |    - name:     SAP HR 6.08
    |      version:  608
    |      archive:  SAP_HR608.SAR
    |
    |    - name:     S4COREOP 104
    |      version:  104
    |      archive:  S4COREOP104.SAR
    |
[8] |  templates:
    |    - name:     S4HANA_1909_SP2_v001
```

### Create BoM Header

1. `[1]` and `[2]`: Record appropriate names for the build and target. The `name` must be the same as the BoM folder name in the Storage Account.

### Define BoM Version

1. `[3]` is an arbitrary number, chosen by you, which can be used to distinguish between any different versions you may have of this particular BoM. The value here should match the `_v...` numbering in the `bom.yml` parent folder, as described earlier.

### Create Defaults Section

1. `[4]`: This section contains:
   1. `archive_location`: The location to which you will upload the SAP build files. Also, the same location from which the files will be copied to the target server.
   1. `target_location`: The folder on the target server, into which the files will be copied for installation.

### Create Materials Section

1. `[5]`: Use exactly as shown. This specifies the start of the list of materials needed.

1. `[6]`: You may have dependencies on other BoMs (for example for HANA, as shown here). In order fully define the materials for this build, you should add these dependencies here.

### Create List of Media

1. `[7]`: Specify `media:` exactly as shown.

1. Using **your editor**, open the download basket spreadsheet. This will render as XML.
1. Ensure the XML is formatted for human readability.
1. Using your editor, transcribe the description and filename as `- name` and `archive` respectively into your `bom.yml` file. Do this for the *whole file* under a `media` section as indicated in the example. :information_source: The `version` property is optional.
1. You will need the blue-ringed number in the next section, so record it along with the entry you are making in your `bom.yml`. For example, add the number as a comment.

   ![SAP Download Basket Spreadsheet](../images/sap-xls-download-basket-xml.png)

   ```text
   - name: "SAP IGS Fonts and Textures"
     archive: "igshelper_17-10010245.sar"
     # 61489

     ... etc ...
   ```

### Include SAP Permalink References

1. Open the `DownloadBasket.json` in your editor and reformat to make it more human readable.

   ![SAP Download Basket Manifest](../images/sap-download-basket-json.png)

1. For each of the `"Value":` lines, take the first, second and fourth items from the following vertical-bar separated values. For example:

   ```text
        "Value": "0020000000703122018|SP_B|SAP IGS Fonts and Textures|61489|1|20201023150931|0"
   ```

   Will give you `0020000000703122018`, `SP_B` and `61489`.

   Using the third value (61489 in this example) as a key, match up the results with the values you recorded as comments in the previous phase.

   ```text
   - name: "SAP IGS Fonts and Textures"
     archive: "igshelper_17-10010245.sar"
     # 61489
   ```

1. For each entry matched, add a `sapurl:` value based on the number up to the first vertical bar. Each entry should include the SAP software download URI location. You may delete the comment. For example:

   ```text
   ```text
   - name: "SAP IGS Fonts and Textures"
     archive: "igshelper_17-10010245.sar"
     sapurl: "https://softwaredownloads.sap.com/file/0020000000703122018"
   ```

1. The other part (`SP_B` in the examples shown) has these observed values:

   1. `SP_B`: These appear to be kernel binary files.
   1. `SPAT`: These appear to be non-kernel binary files.
   1. `CD`: These appear to be database exports.

### Override Target Destination

Files downloaded or shared from the archive space will need to be extracted to the correct location on the target server. This is normally set using the `defaults -> target_location` property (see [the defaults section](#red_circle-create-defaults-section)). However, you may override this on a case-by-case basis.

1. For each relevant entry in the BoM `media` section, add an `override_target_location:` property with the correct target folder. For example:

   ```text
   - name: "Kernel Part I"
     archive: "SAPEXE_200-80004393.SAR"
     sapurl: "https://softwaredownloads.sap.com/file/0020000001063232020"
     override_target_location: "/usr/sap/install/download_basket/"

   - name: "Kernel Part II (777)"
     archive: "SAPEXEDB_200-80004392.SAR"
     sapurl: "https://softwaredownloads.sap.com/file/0020000001063182020"
     override_target_location: "/usr/sap/install/download_basket/"
   ```

### Override Target Filename

By default, files downloaded or shared from the archive space will be extracted with the same filename as the `archive` filename on the target server.  However, you may override this on a case-by-case basis, although this is not normally necessary.

1. For each relevant entry in the BoM `media` section, add an `override_target_filename:` property with the correct target folder. For example:

   ```text
      - name:     SAPCAR
        version:  7.21
        archive:  SAPCAR_1320-80000935.EXE
        override_target_filename: SAPCAR.EXE
   ```

### Tidy Up Layout

The order of entries in the `media` section does not matter. However, for improved readability, you may wish to group related items together.

### Add Template Name

1. [8]: Create a `templates` section as shown, with the same template name as the BoM itself. Note that the extensions `.params` and `.params.xml` are not specified.

   :information_source: The `version` is optional. For example:

   ```text
     templates:
       - name:     S4HANA_1909_SP2_v001
         version:  001
   ```

### Upload Files to Archive Location

1. From the correct Azure storage account, navigate to "Containers", then to "sapbits";
1. In the panel on the right, click Select a file;
1. Navigate your workstation to your working directory;
1. Select `bom.yml`;
1. Click Advanced to show the advanced options, and enter `boms/<Stack_Version>` for the Upload Directory.

## Results and Outputs

1. A `bom.yml` file present in the Storage Account in the correct location. In this example, `sapbits/boms/HANA2_00_052_v001/bom.yml`.
