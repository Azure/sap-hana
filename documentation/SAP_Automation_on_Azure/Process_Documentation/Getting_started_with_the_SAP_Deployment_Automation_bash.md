# Running the automation from Linux


## **Pre-Requisites**

1. **Terraform** - Terraform can be downloaded from [Download Terraform - Terraform by HashiCorp](https://www.terraform.io/downloads.html).
2. **Azure CLI** - Azure CLI can be installed from <https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=script>

## **Deployment** ##

1. Navigate to the home root directory
2. Create a directory "Azure_SAP_Automated_Deployment"
3. Navigate to that directory and clone the sap-hana repository by running:

```bash
git clone <https://github.com/Azure/sap-hana.git> 

cd sap-hana

git checkout beta
```

**Note** If using the deployer the repository is already cloned.

4. Export the required environment variables

    ```bash
    export DEPLOYMENT_REPO_PATH=~/Azure_SAP_Automated_Deployment/sap-hana/
    export ARM_SUBSCRIPTION_ID=8d8422a3-a9c1-4fe9-b880-adcf61557c71

5. Copy the sample parameter folders with

    ```bash
    cd ~/Azure_SAP_Automated_Deployment
    cp sap-hana/documentation/SAP_Automation_on_Azure/Process_Documentation/WORKSPACES WORKSPACES/ -r
    ```

Navigate to the ~/Azure_SAP_Automated_Deployment/WORKSPACES/DEPLOYMENT-ORCHESTRATION folder.

The deployment will need the Service Principal details (application id, secret and tenant ID)

## **Listing the contents of the deployment**

For a highlevel overview of what will be deployed use the validate.sh script to list the resources deployed by the deployment. **Note** The list does not contain all artifacts

```bash
 ${DEPLOYMENT_REPO_PATH}deploy/scripts/validate.sh -p DEPLOYER/MGMT-WEEU-DEP00-INFRASTRUCTURE/MGMT-WEEU-DEP00-INFRASTRUCTURE.json -t sap_deployer

${DEPLOYMENT_REPO_PATH}deploy/scripts/validate.sh -p LIBRARY/MGMT-WEEU-SAP_LIBRARY/MGMT-WEEU-SAP_LIBRARY.json -t sap_library

${DEPLOYMENT_REPO_PATH}deploy/scripts/validate.sh -p LANDSCAPE/DEV-WEEU-SAP01-INFRASTRUCTURE/DEV-WEEU-SAP01-INFRASTRUCTURE.json -t sap_landscape

${DEPLOYMENT_REPO_PATH}deploy/scripts/validate.sh -p SYSTEM/DEV-WEEU-SAP01-ZZZ/DEV-WEEU-SAP01-ZZZ.json -t sap_system

```

A sample output is listed below

```txt
    Deployment information
    ----------------------------------------------------------------------------
    Environment:                  DEV
    Region:                       westeurope
    * Resource group:             (name defined by automation)

    Networking
    ----------------------------------------------------------------------------
    VNet Logical Name:            SAP01
    * Admin subnet:               (name defined by automation)
    * Admin subnet prefix:        10.110.0.0/27
    * Admin subnet nsg:           (name defined by automation)
    * Database subnet:            (name defined by automation)
    * Database subnet prefix:     10.110.0.64/27
    * Database subnet nsg:        (name defined by automation)
    * Application subnet:         (name defined by automation)
    * Application subnet prefix:  10.110.0.32/27
    * Application subnet nsg:     (name defined by automation)
    * Web subnet:                 (name defined by automation)
    * Web subnet prefix:          10.110.0.96/27
    * Web subnet nsg:             (name defined by automation)

    Database tier
    ----------------------------------------------------------------------------
    Platform:                     HANA
    High availability:            false
    Number of servers:            1
    Database sizing:              Default
    Image publisher:              SUSE
    Image offer:                  sles-sap-12-sp5
    Image sku:                    gen1
    Image version:                latest
    Deployment:                   Regional
    Networking:                   Use Azure provided IP addresses
    Authentication:               key

    Application tier
    ----------------------------------------------------------------------------
    Authentication:               key
    Application servers
    Number of servers:          2
    Image publisher:            SUSE
    Image offer:                sles-sap-12-sp5
    Image sku:                  gen1
    Image version:              latest
    Deployment:                 Regional
    Central Services
    Number of servers:          1
    High availability:          true
    Image publisher:            SUSE
    Image offer:                sles-sap-12-sp5
    Image sku:                  gen1
    Image version:              latest
    Deployment:                 Regional
    Web dispatcher
    Number of servers:          1
    Image publisher:            SUSE
    Image offer:                sles-sap-12-sp5
    Image sku:                  gen1
    Image version:              latest
    Deployment:                 Regional

    Key Vault
    ----------------------------------------------------------------------------
    SPN Key Vault:              Deployer keyvault
    User Key Vault:             Workload keyvault
    Automation Key Vault:       Workload keyvault

```

## **Preparing the region**

For deploying the supporting infrastructure for the Azure region(Deployer, Library) use the prepare_region.sh script

```bash
${DEPLOYMENT_REPO_PATH}deploy/scripts/prepare_region.sh
-d DEPLOYER/MGMT-WEEU-DEP00-INFRASTRUCTURE/MGMT-WEEU-DEP00-INFRASTRUCTURE.json -l LIBRARY/MGMT-WEEU-SAP_LIBRARY/MGMT-WEEU-SAP_LIBRARY.json
```

The script will deploy the deployment infrastructure and create the Azure keyvault for storing the Service Principal details. When prompted for the environment details enter "MGMT" and then enter the Service Principal details. The script will them deploy the rest of the resources required.

## **Deploying the DEV environment**

For deploying the DEV environment (vnet & keyvaults) navigate to the folder(LANDSCAPE/DEV-WEEU-SAP01-INFRASTRUCTURE) containing the DEV-WEEU-SAP01-INFRASTRUCTURE.json parameter file and use the install_workloadzone script.

```bash
${DEPLOYMENT_REPO_PATH}deploy/scripts/install_workloadzone.sh -p DEV-WEEU-SAP01-INFRASTRUCTURE.json 
```

## **Deploying the SAP system**

For deploying the SAP system navigate to the folder(DEV-WEEU-SAP01-ZZZ) containing the DEV-WEEU-SAP01-ZZZ.json parameter file and use the installer.sh script.

```bash
${DEPLOYMENT_REPO_PATH}deploy/scripts/installer.sh -p DEV-WEEU-SAP01-ZZZ.json -t sap_system
```

