### <img src="../../documentation/assets/UnicornSAPBlack256x256.png" width="64px"> SAP Automation > V1.0.0 > HANA <!-- omit in toc -->
# Deployment Environment <!-- omit in toc -->

Master Branch's status: [![Build Status](https://dev.azure.com/azuresaphana/Azure-SAP-HANA/_apis/build/status/Azure.sap-hana?branchName=master&api-version=5.1-preview.1)](https://dev.azure.com/azuresaphana/Azure-SAP-HANA/_build/latest?definitionId=6&branchName=master)

<br>

## Table of contents <!-- omit in toc -->

- [Common Setup](#common-setup)
- [Setup Workspace](#setup-workspace)

<br>

## Common Setup
*This step may have been previously completed*
1. Create an SAP Automation root directory and descend into the newly created <automation_root>

   > `mkdir SAP_Automation_Deployment && cd $_`

2. Clone the Repository.

   - HTTPS

     > `git clone https://github.com/Azure/sap-hana.git`

   - SSH

     > `git clone git@github.com:Azure/sap-hana.git`

<br>

## Setup Workspace

1. Create a *Workspace Container* under the <automation_root> and descend into the newly created *Workspace Container*.

   > `mkdir -p <automation_root>/Terraform/workspace/HANA && cd $_`

2. Create a *Workspace* within the newly created *Workspace Container* and descend into the newly created *Workspace*.
   - We recommend an easily identifiable naming convention that uniquely and globally identify the deployment.
   <br>For example: `HANA-<SID>`
     - The SID    field represents the SAP System ID.

   > `mkdir HANA-<SID> && cd $_`
