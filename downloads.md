# Required SAP packages
This document contains a list of SAP packages used by the automated deployment templates. Before you can run the Terraform modules and Ansible playbooks/roles, you will need to do the following steps:
* use the table below to identify which bits are required for your scenario;
* download all required bits from [SAP's Software Download Center (SWDC)](https://launchpad.support.sap.com/#/softwarecenter);
* upload the bits to an Azure Blob (or any accessible HTTP server) and obtain a download URL;
* adjust the download URL parameters in the relevant terraform.tfvars file accordingly.

**NOTE:** You will need a valid SAP (S-)user to access SWDC. 

### List of bits used by Terraform/Ansible templates
| Name | OS | Version | SWDC filename | Scenario | Template parameter |
| ---- | -- | ------- | ------------- | ---------| ------------------ |
| SAPCAR | Linux x86_64 | 7.21 | SAPCAR_1110-80000935.EXE | All | url_sap_sapcar |
| SAPCAR | Windows 64-bit | 7.21 | SAPCAR_1110-80000938.EXE | Windows bastion host | url_sap_sapcar_win |
| SAP Host Agent | Linux x86_64 | 7.21 SP36 | SAPHOSTAGENT36_36-20009394.SAR | All | url_sap_hostagent |
| HANA DB Server | Linux x86_64 | 122.17 (SPS12) for HANA DB 1.00 | IMDB_SERVER100_122_17-10009569.SAR | HANA 1.0 landscapes | url_sap_hdbserver |
| HANA DB Server | Linux x86_64 | 2.00.32 for HANA DB 2.00 | IMDB_SERVER20_032_0-80002031.SAR | HANA 2.0 landscapes | url_sap_hdbserver |
| HANA Studio | Windows 64-bit | 122.20 (SPS12) for HANA DB 1.00 | IMC_STUDIO2_122_20-80000321.SAR | Windows bastion host | url_hana_studio | 
| XS Advanced Runtime | | SP00 Patch87 | EXTAPPSER00P_87-70001316.SAR | XSA | url_xsa_runtime |
| DI Core | | SP12 Patch9 | XSACDEVXDI12_9-70001255.ZIP | XSA | url_di_core |
| SAPUI5 | | SP52 Patch19 | XSACUI5FESV452P_19-70003351.ZIP | XSA | url_sapui5 | 
| Portal Services | | SP02 Patch3 | XSACPORTALSERV02_3-80002098.ZIP | XSA | url_portal_services | 
| XS Services | | SP06 Patch9 | XSACSERVICES06_9-70002361.ZIP | XSA | url_xs_services
| HANA Cockpit 2.0 | | SP07 Patch11 | SAPHANACOCKPIT07_11-70002299.SAR | XSA + Cockpit | url_cockpit |
| SHINE Content (XSA) | | SP05 Patch3 | XSACSHINE05_3-70002323.ZIP | XSA + SHINE | url_shine_xsa |

