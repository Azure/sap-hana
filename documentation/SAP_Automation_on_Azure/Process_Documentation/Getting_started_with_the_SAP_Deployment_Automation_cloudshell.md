# Running the automation from Azure cloud shell

The Azure cloud shell has all the prerequisites for deployment, as it as both the Azure CLI and Terraform installed.

## **Preparing the cloud shell**

To be able to run the deployments from the cloud shell we need to clone the sap-hana repository to a directory in cloud shell.

Open the cloud shell and use bash.

1. Navigate to the root directory of the cloud shell
2. Create a directory “Azure_SAP_Automated_Deployment”
3. Clone the sap-hana repository by running:

```bash
git clone <https://github.com/Azure/sap-hana.git> 

cd sap-hana

git checkout beta
```

4. Export the required environment variables

```bash
export DEPLOYMENT_REPO_PATH=~/Azure_SAP_Automated_Deployment/sap-hana/
export ARM_SUBSCRIPTION_ID=8d8422a3-a9c1-4fe9-b880-adcf61557c71
```

5. Copy the sample parameter folders with

```bash
cp sap-hana/documentation/SAP_Automation_on_Azure/Process_Documentation/WORKSPACES WORKSPACES/ -r
```

Navigate to the ~/Azure_SAP_Automated_Deployment/WORKSPACES/DEPLOYMENT-ORCHESTRATION folder.

The deployment will need the Service Principal details (application id, secret and tenant ID)

## **Deploying the environment**

For deploying the supporting infrastructure (Deployer, Library and Workload zone) use the install_environment.sh script 

```bash
${DEPLOYMENT_REPO_PATH}deploy/scripts/install_environment
-d DEPLOYER/DEV-WEEU-DEP00-INFRASTRUCTURE/DEV-WEEU-DEP00-INFRASTRUCTURE.json -l LIBRARY/DEV-WEEU-SAP_LIBRARY/DEV-WEEU-SAP_LIBRARY.json -e LANDSCAPE/DEV-WEEU-SAP01-INFRASTRUCTURE/DEV-WEEU-SAP01-INFRASTRUCTURE.json
```

The script will deploy the deployment infrastructure and create the Azure keyvault for storing the Service Principal details. When prompted for the environment details enter “DEV” and then enter the Service Principal details. The script will them deploy the rest of the resources required.

## **Deploying the SAP system**

For deploying the SAP system navigate to the folder containing the parameter file and use the installer.sh script 

${DEPLOYMENT_REPO_PATH}deploy/scripts/installer.sh -p DEV-WEEU-SAP01-ZZZ.json -t sap_system
