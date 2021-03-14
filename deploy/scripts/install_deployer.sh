#!/bin/bash

function showhelp {
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#                                                                                       #" 
    echo "#   This file contains the logic to deploy the deployer.                                #" 
    echo "#   The script experts the following exports:                                           #" 
    echo "#                                                                                       #" 
    echo "#     ARM_SUBSCRIPTION_ID to specify which subscription to deploy to                    #" 
    echo "#     DEPLOYMENT_REPO_PATH the path to the folder containing the cloned sap-hana        #" 
    echo "#                                                                                       #" 
    echo "#   The script will persist the parameters needed between the executions in the         #" 
    echo "#   ~/.sap_deployment_automation folder                                                 #" 
    echo "#                                                                                       #" 
    echo "#                                                                                       #" 
    echo "#   Usage: install_deployer.sh                                                          #"
    echo "#    -p deployer parameter file                                                         #"
    echo "#                                                                                       #" 
    echo "#    -i interactive true/false setting the value to false will not prompt before apply  #"
    echo "#    -h Show help                                                                       #"
    echo "#                                                                                       #" 
    echo "#   Example:                                                                            #" 
    echo "#                                                                                       #" 
    echo "#   [REPO-ROOT]deploy/scripts/install_deployer.sh \                                     #"
	echo "#      -p PROD-WEEU-DEP00-INFRASTRUCTURE.json \                                         #"
	echo "#      -i true                                                                          #" 
    echo "#                                                                                       #" 
    echo "#########################################################################################"
}

while getopts ":p:i:h" option; do
    case "${option}" in
        p) parameterfile=${OPTARG};;
        i) interactive=${OPTARG};;
        h) showhelp
           exit 3
           ;;
        ?) echo "Invalid option: -${OPTARG}."
           exit 2
           ;; 
    esac
done

deployment_system=sap_deployer

environment=$(grep "environment" "${parameterfile}" -m1  | cut -d: -f2 | cut -d, -f1 | tr -d \")
region=$(grep "region" "${parameterfile}" -m1  | cut -d: -f2 | cut -d, -f1 | tr -d \")

key=$(echo "${parameterfile}" | cut -d. -f1)

if [ ! -f "${parameterfile}" ]
then
    printf -v val %-40.40s "$parameterfile"
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #" 
    echo "#               Parameter file does not exist: ${val} #"
    echo "#                                                                                       #" 
    echo "#########################################################################################"
    exit
fi

#Persisting the parameters across executions
automation_config_directory=~/.sap_deployment_automation/
generic_config_information="${automation_config_directory}"config
deployer_config_information="${automation_config_directory}""${region}"

arm_config_stored=false
config_stored=false

if [ ! -d "${automation_config_directory}" ]
then
    # No configuration directory exists
    mkdir "${automation_config_directory}"
    if [ -n "${DEPLOYMENT_REPO_PATH}" ]; then
        # Store repo path in ~/.sap_deployment_automation/config
        echo "DEPLOYMENT_REPO_PATH=${DEPLOYMENT_REPO_PATH}" >> "${generic_config_information}"
        config_stored=true
    fi
    if [ -n "$ARM_SUBSCRIPTION_ID" ]; then
        # Store ARM Subscription info in ~/.sap_deployment_automation
        echo "ARM_SUBSCRIPTION_ID=${ARM_SUBSCRIPTION_ID}" >> $deployer_config_information
        arm_config_stored=true
    fi

else
    temp=$(grep "DEPLOYMENT_REPO_PATH" "${generic_config_information}")
    if [ $temp ]
    then
        # Repo path was specified in ~/.sap_deployment_automation/config
        DEPLOYMENT_REPO_PATH=$(echo "${temp}" | cut -d= -f2)
        config_stored=true
    fi
fi

if [ ! -n "${DEPLOYMENT_REPO_PATH}" ]; then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #" 
    echo "#   Missing environment variables (DEPLOYMENT_REPO_PATH)!!!                             #"
    echo "#                                                                                       #" 
    echo "#   Please export the folloing variables:                                               #"
    echo "#      DEPLOYMENT_REPO_PATH (path to the repo folder (sap-hana))                        #"
    echo "#      ARM_SUBSCRIPTION_ID (subscription containing the state file storage account)     #"
    echo "#                                                                                       #" 
    echo "#########################################################################################"
    exit 4
else
    if [ $config_stored == false ]
    then
        echo "DEPLOYMENT_REPO_PATH=${DEPLOYMENT_REPO_PATH}" >> ${automation_config_directory}config
    fi
fi

temp=$(grep "ARM_SUBSCRIPTION_ID" $deployer_config_information | cut -d= -f2)
templen=$(echo $temp | wc -c)
# Subscription length is 37

if [ 37 == $templen ] 
then
    echo "Reading the configuration"
    # ARM_SUBSCRIPTION_ID was specified in ~/.sap_deployment_automation/configuration file for deployer
    ARM_SUBSCRIPTION_ID="${temp}"
    arm_config_stored=true
else    
    arm_config_stored=false
fi

if [ ! -n "$ARM_SUBSCRIPTION_ID" ]; then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #" 
    echo "#   Missing environment variables (ARM_SUBSCRIPTION_ID)!!!                              #"
    echo "#                                                                                       #" 
    echo "#   Please export the folloing variables:                                               #"
    echo "#      DEPLOYMENT_REPO_PATH (path to the repo folder (sap-hana))                        #"
    echo "#      ARM_SUBSCRIPTION_ID (subscription containing the state file storage account)     #"
    echo "#                                                                                       #" 
    echo "#########################################################################################"
    exit 3
else
    if [  $arm_config_stored  == false ]
    then
        echo "Storing the configuration"
        sed -i /ARM_SUBSCRIPTION_ID/d  "${deployer_config_information}"
        echo "ARM_SUBSCRIPTION_ID=${ARM_SUBSCRIPTION_ID}" >> "${deployer_config_information}"
    fi
fi

terraform_module_directory="${DEPLOYMENT_REPO_PATH}"deploy/terraform/bootstrap/"${deployment_system}"/

ok_to_proceed=false
new_deployment=false

 if [ ! -d ./.terraform/ ]; then
    echo "#########################################################################################"
    echo "#                                                                                       #" 
    echo "#                                   New deployment                                      #"
    echo "#                                                                                       #" 
    echo "#########################################################################################"
    terraform init -upgrade=true "${terraform_module_directory}"
else
    echo "#########################################################################################"
    echo "#                                                                                       #" 
    echo "#                          .terraform directory already exists!                         #"
    echo "#                                                                                       #" 
    echo "#########################################################################################"
    read -p "Do you want to redeploy Y/N?"  ans
    answer=${ans^^}
    if [ $answer == 'Y' ]; then

        if [ -f ./.terraform/terraform.tfstate ]; then
            if grep "azurerm" ./.terraform/terraform.tfstate ; then
                echo "#########################################################################################"
                echo "#                                                                                       #" 
                echo "#                     The state is already migrated to Azure!!!                         #"
                echo "#                                                                                       #" 
                echo "#########################################################################################"
                return 0
            fi
        fi
        
        terraform init -upgrade=true -reconfigure "${terraform_module_directory}"
        terraform refresh -var-file="${parameterfile}" "${terraform_module_directory}"
    else
        exit 0
    fi
 fi

echo ""
echo "#########################################################################################"
echo "#                                                                                       #" 
echo "#                             Running Terraform plan                                    #"
echo "#                                                                                       #" 
echo "#########################################################################################"
echo ""

terraform plan -var-file="${parameterfile}" "$terraform_module_directory"

echo ""
echo "#########################################################################################"
echo "#                                                                                       #" 
echo "#                             Running Terraform apply                                   #"
echo "#                                                                                       #" 
echo "#########################################################################################"
echo ""

terraform apply ${approve} -var-file="${parameterfile}" "${terraform_module_directory}"

cat <<EOF > backend.tf
####################################################
# To overcome terraform issue                      #
####################################################
terraform {
    backend "local" {}
}
EOF

kv_name=$(terraform output deployer_kv_user_name | tr -d \") 

temp=$(echo "${kv_name}" | grep "Warning")
if [ -z "${temp}" ]
then
    temp=$(echo "${kv_name}" | grep "Backend reinitialization required")
    if [ -z "${temp}" ]
    then
        touch "${deployer_config_information}"
        sed -i /keyvault/d  "${deployer_config_information}"
        echo "keyvault=${kv_name}" >> "${deployer_config_information}"
    fi
fi

rm backend.tf

exit 0