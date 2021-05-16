# ![SAP Deployment Automation Framework](../assets/images/UnicornSAPBlack64x64.png)**SAP Deployment Automation Framework** #

# **SPN Creation** #

## Overview

The Framework uses Service Principals to deploy resources into a subscription.
The Environment input is used as a key to lookup the SPN information from the keyVault.
This allows for mapping of an environment to a subscription, along with credentials.

Repeat this process for each unique Service Principal needed for the workloads.

The Service Principals can be created using the following steps.

## SPN Creation 

1. Create SPN

From a privilaged account, create an Service Principal using the following commands. Please use a descriptive name that includes the environment name.

   ```bash
   az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" --name="MGMT-Deployment-Account"
   ```

2. Record the credential outputs.

   The pertinant fields are:
   - appId
   - password
   - tenant

```json
    {
      "appId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
      "displayName": "MGMT-Deployment-Account",
      "name": "http://MGMT-Deployment-Account",
      "password": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
      "tenant": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx""
    }
 ```

3. Add User Access Administrator Role Assignment to the Service Principal.

   ```bash
   az role assignment create --assignee <appId> --role "User Access Administrator"
   ```