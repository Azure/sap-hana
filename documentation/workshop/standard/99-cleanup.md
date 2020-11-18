### <img src="../../../../documentation/SAP_Automation_on_Azure/assets/images/UnicornSAPBlack256x256.png" width="64px"> SAP Automation > V1.x.x <!-- omit in toc -->
# Cleanup <!-- omit in toc -->

<br/>

## Table of contents <!-- omit in toc -->



<br/>

## Overview


---

<br/><br/>

## Procedure

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

### Destroy Workload VNET

```
cd ~/Azure_SAP_Automated_Deployment/WORKSPACES/SAP_LANDSCAPE/NP-EUS2-SAP00-INFRASTRUCTURE
```


```
terraform destroy --auto-approve                                                        \
                  --var-file=NP-EUS2-SAP00-INFRASTRUCTURE.json                           \
                  ../../../sap-hana/deploy/terraform/run/sap_system/
```