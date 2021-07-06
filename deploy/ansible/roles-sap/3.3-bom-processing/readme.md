# Process Bill of Materials

This role recursively travels BoM files (`bom.yaml`) and copies files from the "sapbits" archive Storage Account, `sapbits_location_base_path` + `sapbits_bom_files` to the given `target_media_location`. The initial BoM is specified by the `bom_base_name` variable.

Optionally, a `test_mode` variable may be used and set to `true`, which will recursively travel the BoM files and report files to be copied, without actually copying them.

For example:

```text
---

- hosts:      "{{ sap_sid|upper }}_SCS"
  vars:
    sapbits_location_base_path:   https://npeus2saplibb546.blob.core.windows.net/sapbits
    sapbits_bom_files:            sapfiles
    bom_base_name:                S4HANA_2020_ISS_v001
    target_media_location:        /usr/sap/install
    test_mode:                    true

  roles:
    - role: role-sap/process_bom
```
