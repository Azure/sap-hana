### <img src="../../../assets/images/UnicornSAPBlack256x256.png" width="64px"> SAP Deployment Automation Framework <!-- omit in toc -->
<br/><br/>

# Cleanup <!-- omit in toc -->

<br/>

## Table of contents <!-- omit in toc -->

- [Overview](#overview)
- [Procedure](#procedure)
  - [Destroy SDU](#destroy-sdu)
  - [Destroy Workload VNET](#destroy-workload-vnet)
  - [Destroy Region](#destroy-region)

<br/><br/>

## Overview

Execute the first two steps from the deployer VM.

Execute the destroy region command from the cloud shell.


---

<br/><br/>

## Procedure
<br/>

### Destroy SDU
<br/>

```
cd ~/Azure_SAP_Automated_Deployment/WORKSPACES/SAP_SYSTEM/DEMO-SCUS-SAP00-X00
```


```
$DEPLOYMENT_REPO_PATH/deploy/scripts/remover.sh            \
     --parameterfile DEMO-SCUS-SAP00-X00.json              \
     --type sap_system
```
<br/><br/>


### Destroy Workload VNET
<br/>

```
cd ~/Azure_SAP_Automated_Deployment/WORKSPACES/SAP_LANDSCAPE/DEMO-SCUS-SAP00-INFRASTRUCTURE
```


```
$DEPLOYMENT_REPO_PATH/deploy/scripts/remover.sh            \
     --parameterfile DEMO-SCUS-SAP00-INFRASTRUCTURE.json              \
     --type sap_landscape
```
<br/><br/>

### Destroy region

Execute this in the cloud shell
<br/>

```bash
   cd ~/Azure_SAP_Automated_Deployment/WORKSPACES


   ${DEPLOYMENT_REPO_PATH}/deploy/scripts/remove_region.sh                                                     \
        --deployer_parameter_file DEPLOYER/DEMO-SCUS-DEP00-INFRASTRUCTURE/DEMO-SCUS-DEP00-INFRASTRUCTURE.json  \
        --library_parameter_file LIBRARY/DEMO-SCUS-SAP_LIBRARY/DEMO-SCUS-SAP_LIBRARY.json                      
        
```
