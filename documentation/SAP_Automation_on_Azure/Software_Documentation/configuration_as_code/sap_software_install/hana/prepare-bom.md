# HANA BoM Preparation

:hand: The Preparation phase for SAP HANA should only be completed once for each version of SAP HANA used. It is possible multiple SAP Application BoMs will reference the same SAP HANA BoM.

## Prerequisites

1. An editor for creating the HANA BoM file.
1. A HANA installation template uploaded to the Storage Account.
1. SAP HANA media present on the Storage Account.
1. An empty folder in which to create the BoM file.

## Inputs

1. List of archive media for this version of HANA.

## Example Partial BoM File

An example of a small part of a BoM file for HANA2.0 is shown, below. The `[x]` numbered sections are covered in the following documentation. Note that `v001` is a sequential number used to indicate the internal (non-SAP) version of the files included.

Note that the `name` property is optional in `media`, `stackfiles` and `templates`. If provided, it will be used by the BoM validator to note entries having errors.

Complete, usable BoM files are available in the [examples](../examples/) directory.

```text
step|BoM Content
    |
    |---
    |
[1] |name:    'HANA_2_00_052_v001'
[2] |target:  'HANA 2.0'
    |
[3] |defaults:
    |  target_location: "{{ target_media_location }}/download_basket/"
    |
[4] |materials:
[5] |  media:
    |    - name:     SAPCAR
    |      archive:  SAPCAR_1324-80000935.EXE
    |      override_target_filename: "SAPCAR.EXE"
    |
    |    - name:     "LCAPPS for HANA 2.00.052.00 Build 100.46 PL 029"
    |      archive:  IMDB_LCAPPS_2052_0-20010426.SAR
    |
    |    - name:     "Revision 2.00.052.0 (SPS05) for HANA DB 2.0"
    |      archive:  IMDB_SERVER20_052_0-80002031.SAR
    |
    |    - name:     "Client for HANA 2"
    |      archive:  IMDB_CLIENT20_006_58-80002082.SAR
    |
[6] |  templates:
    |    - name:     HANA params
    |      file:     HANA_2_00_052_v001.params
    |      override_target_location: "{{ target_media_location }}/config"
    |
    |    - name:     HANA xml
    |      file:     HANA_2_00_052_v001.params.xml
    |      override_target_location: "{{ target_media_location }}/config"
    |
[7] |  stackfiles:
    |    - name: Download Basket permalinks
    |      file: myDownloadBasketFiles.txt
    |      override_target_location: "{{ target_media_location }}/config"
    |...
```

## Process

1. Within your working folder, create an empty text file called `bom.yml`.

   ```text
   .
   └── bom.yml      <-- BoM content will go in here
   ```

### Create BoM Header

1. `[1]` and `[2]`: Record appropriate names for the build and target. The `name` should be the same as that recorded in the Storage Account under `sapbits/boms`.

### Create Defaults Section

1. `[3]`: This section contains:
   1. `target_location`: The folder on the target server, into which the files will be copied for installation. Normally, this will reference `{{ target_media_location }}` as shown, but could be an unrelated path.

### Create Materials Section

1. `[4]`: Use exactly as shown. This specifies the start of the list of materials needed.

### Create List of Media

1. `[5]`: Specify `media:` exactly as shown.

1. Using your editor, for each item in your Download Basket, provide a suitable, descriptive name and filename as `- name` and `archive` respectively into your `bom.yml` file.

   ```text
   - name:     SAPCAR
     archive:  SAPCAR_1320-80000935.EXE

   - name:     IMDB LCAPPS 2.052
     archive:  IMDB_LCAPPS_2052_0-20010426.SAR

   - name:     HANA 2.0
     archive:  51054623.ZIP
   ```

### Add Templates Section

1. `[6]`: Create a blank `templates` section as shown below.

   ```text
     templates:

   ```

### Add Stackfiles Section

1. `[7]`: Create a `stackfiles` section as shown from the steps at the start of **[Process](#process)**.

   ```text
   stackfiles:
     - name: Download Basket permalinks
       file: myDownloadBasketFiles.txt
   ```

### Override Target Destination

Files downloaded or shared from the archive space will need to be extracted to the correct location on the target server. This is normally set using the `defaults -> target_location` property (see [the defaults section](#create-defaults-section)). However, you may override this on a case-by-case basis as shown. Overrides will normally reference `{{ target_media_location }}` as shown, but could be an unrelated path.

1. For each relevant entry in the BoM `media` section, add an `override_target_location:` property with the correct target folder. For example:

   ```text
     - name: Download Basket permalinks
       file: myDownloadBasketFiles.txt
       override_target_location: "{{ target_media_location }}/config"
   ```

### Override Target Filename

By default, files downloaded or shared from the archive space will be extracted with the same filename as the `archive` filename on the target server.  However, you may override this on a case-by-case basis, although this is not normally necessary.

1. For each relevant entry in the BoM `media` section, add an `override_target_filename:` property with the correct target folder. For example:

   ```text
      - name:     SAPCAR
        archive:  SAPCAR_1320-80000935.EXE
        override_target_filename: SAPCAR.EXE
   ```

### Tidy Up Layout

The order of entries in the `media` section does not matter. However, for improved readability, you may wish to group related items together.

### Validate the BoM

1. [Validate the BoM](../bom-validation.md)

### Upload Files to Archive Location

1. From the correct Azure storage account, navigate to "File shares", then to "sapbits".
1. For the `boms` folder in sapbits:
   1. Click the correct BoM folder name in the portal to open. In this example, that would be `HANA_2_00_052_v001`, then:
   1. Click "Upload" and select the `bom.yml` file from your workstation for upload.
   1. Click "Upload".

## Results and Outputs

1. A `bom.yml` file present in the Storage Account in the correct location. In this example, `sapbits/boms/HANA_2_00_052_v001/bom.yml`.

## Follow on Process

- [Deploy System Infrastructure](../deploy-system-infrastructure.md)
