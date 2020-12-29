### <img src="../../../../../../assets/images/UnicornSAPBlack256x256.png" width="64px"> SAP Deployment Automation Framework <!-- omit in toc -->
<br/><br/>

# Cleanup <!-- omit in toc -->

<br/>

## Table of contents <!-- omit in toc -->

- [Overview](#overview)
- [Procedure](#procedure)
  - [Destroy SDU](#destroy-sdu)
  - [Destroy Workload VNET](#destroy-workload-vnet)

<br/><br/>

## Overview


---

<br/><br/>

## Procedure
<br/>

### Destroy SDU
<br/>

```
cd ~/Azure_SAP_Automated_Deployment/WORKSPACES/SAP_SYSTEM/NP-EUS2-SAP00-X00
```


```
terraform destroy --auto-approve                                                        \
                  --var-file=NP-EUS2-SAP00-X00.json                                      \
                  ../../../sap-hana/deploy/terraform/run/sap_system/
```
<br/><br/>


### Destroy Workload VNET
<br/>

```
cd ~/Azure_SAP_Automated_Deployment/WORKSPACES/SAP_LANDSCAPE/NP-EUS2-SAP00-INFRASTRUCTURE
```


```
terraform destroy --auto-approve                                                        \
                  --var-file=NP-EUS2-SAP00-INFRASTRUCTURE.json                           \
                  ../../../sap-hana/deploy/terraform/run/sap_system/
```
<br/><br/>
