### <img src="../documentation/assets/UnicornSAPBlack256x256.png" width="64px"> SAP Automation > V1.0.0 <!-- omit in toc -->
# Getting Started <!-- omit in toc -->

Master Branch's status: [![Build Status](https://dev.azure.com/azuresaphana/Azure-SAP-HANA/_apis/build/status/Azure.sap-hana?branchName=master&api-version=5.1-preview.1)](https://dev.azure.com/azuresaphana/Azure-SAP-HANA/_build/latest?definitionId=6&branchName=master)

<br>

## Table of contents <!-- omit in toc -->
- [Getting Started](#getting-started)
- [Preparing your environment](#preparing-your-environment)

<br>

## Getting Started

## Preparing your environment
1. You have several options from where to run the automated deployment:
   * **Local deployments:** Open a shell on your local machine (Works on a Unix based system (i.e. MacOS, Linux, Cygwin, or Windows Subsystem for Linux)).
   * **VM deployment:** Connect to your VM using an SSH client.
   * **Cloud Shell deployment:** From your Azure Portal, open your Cloud Shell (`>_` button in top bar).
   
   *(**Note**: Cloud Shell comes pre-installed with Terraform 0.12 which is now compatible with our scripts.)*
   
2. Install the following software on your deployment machine as needed (not required for deployments on Cloud Shell):
   * [Terraform](https://www.terraform.io/downloads.html)

   *(**Note**: The scripts have been tested with Terraform `v0.12.12` and Ansible `2.8`)* <!-- TODO: Update Versions -->

3. Install the [Azure Command-Line Interface (CLI)](https://docs.microsoft.com/en-us/cli/azure/?view=azure-cli-latest) (If required)

4. Log into your Azure subscription:

    ```sh
    az login
    ```

<!-- TODO: SPN process needs to be improved -->
5. Create a service principal that will be used to manage Azure resources on your behalf:

    ```sh
    az ad sp create-for-rbac --name <service-principal-name>
    ```
    
   *(**Note**: You can find additional information on creating service principals on [this page](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli?toc=%2Fen-us%2Fazure%2Fazure-resource-manager%2Ftoc.json&bc=%2Fen-us%2Fazure%2Fbread%2Ftoc.json&view=azure-cli-latest).)*

6. You will see an output similar to this:

   ```{
     "appId": "<service-principal-app-id>",
     "displayName": "<service-principal-name>",
     "name": "http://<service-principal-name>",
     "password": "<service-principal-password>",
     "tenant": "<service-principal-tenant-id>"
   }
   ```

7. Set the details of the service principal as environment variables:

    ```sh
    # configure service principal for Terraform on Linux/MacOS
    export ARM_SUBSCRIPTION_ID='<azure-subscription-id>'
    export ARM_CLIENT_ID='<service-principal-app-id>'
    export ARM_CLIENT_SECRET='<service-principal-password>'
    export ARM_TENANT_ID='<service-principal-tenant-id>'
    ```

    ```powershell
    # configure service principal for Terraform on Windows
    SETX ARM_SUBSCRIPTION_ID <azure-subscription-id>
    SETX ARM_CLIENT_ID <service-principal-app-id>
    SETX ARM_CLIENT_SECRET <service-principal-password>
    SETX ARM_TENANT_ID <service-principal-tenant-id>
    ```    

   *(**Note**: While you set the environment variables every time, the recommended way is to create a file ```set-sp.sh``` or ```set-sp.cmd``` and copy the above contents into it; this way, you can just run the script by executing ```source set-sp.sh``` or ```set-sp.cmd```.)*


