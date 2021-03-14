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
    echo "#    -i interactive true/false setting the value to false will not prompt before apply  #"
    echo "#    -h Show help                                                                       #"
    echo "#                                                                                       #" 
    echo "#   Example:                                                                            #" 
    echo "#                                                                                       #" 
    echo "#   [REPO-ROOT]deploy/scripts/install_library.sh \                                      #"
	echo "#      -p PROD-WEEU-SAP_LIBRARY.json \                                                  #"
	echo "#      -d ../../DEPLOYER/PROD-WEEU-DEP00-INFRASTRUCTURE/ \                              #"
	echo "#      -i true                                                                          #" 
    echo "#                                                                                       #" 
    echo "#########################################################################################"
}

interactive=true

while getopts ":p:i:d:h" option; do
    case "${option}" in
        p) parameterfile=${OPTARG};;
        i) interactive=${OPTARG};;
        d) deployer_statefile_foldername=${OPTARG};;
        h) showhelp
           exit 3
           ;;
        ?) echo "Invalid option: -${OPTARG}."
           exit 2
           ;; 
    esac
done

# Read environment
environment=$(grep "environment" "${parameterfile}" -m1  | cut -d: -f2 | cut -d, -f1 | tr -d \")
region=$(grep "region" "${parameterfile}" -m1  | cut -d: -f2 | cut -d, -f1 | tr -d \")
key=$(echo "${parameterfile}" | cut -d. -f1)
deployment_system=sap_library

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
library_config_information="${automation_config_directory}""${region}"

arm_config_stored=false
config_stored=false

if [ ! -d "${automation_config_directory}" ]
then
    # No configuration directory exists
    mkdir "$automation_config_directory"

    if [ -n "${DEPLOYMENT_REPO_PATH}" ]; then
        # Store repo path in ~/.sap_deployment_automation/config
        echo "DEPLOYMENT_REPO_PATH=${DEPLOYMENT_REPO_PATH}" >> $generic_config_information
        config_stored=1
    else
        config_stored=0
    fi

    if [ -n "${ARM_SUBSCRIPTION_ID}" ]; then
        # Store ARM Subscription info in ~/.sap_deployment_automation
        echo "ARM_SUBSCRIPTION_ID=${ARM_SUBSCRIPTION_ID}" >> $library_config_information
        arm_config_stored=1
    else    
        arm_config_stored=0
    fi

else
    temp=$(grep "DEPLOYMENT_REPO_PATH" "${generic_config_information}")
    if [ ! -z $temp ]
    then
        # Repo path was specified in ~/.sap_deployment_automation/config
        DEPLOYMENT_REPO_PATH=$(echo "${temp}" | cut -d= -f2)
        config_stored=1
    else
        config_stored=0
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
    exit -1
else
    if [ $config_stored -eq 0 ]
    then
        echo "DEPLOYMENT_REPO_PATH=${DEPLOYMENT_REPO_PATH}" >> ${automation_config_directory}config
    fi
fi

temp=$(grep "ARM_SUBSCRIPTION_ID" $library_config_information)
if [ ! -z $temp ]
then
    echo "Reading the configuration"
    # ARM_SUBSCRIPTION_ID was specified in ~/.sap_deployment_automation/configuration file for library
    ARM_SUBSCRIPTION_ID=$(echo "${temp}" | cut -d= -f2)
    arm_config_stored=1
else    
    echo "No configuration"
    arm_config_stored=0
fi

if [ ! -n "${ARM_SUBSCRIPTION_ID}" ]; then
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
    exit -1
else
    if [ $arm_config_stored -eq 0 ]
    then
        echo "Storing the configuration"
        echo "ARM_SUBSCRIPTION_ID=${ARM_SUBSCRIPTION_ID}" >> ${library_config_information}
    fi
fi

if [ $interactive == false ]; then
    approve="--auto-approve"
fi

terraform_module_directory="${DEPLOYMENT_REPO_PATH}"deploy/terraform/bootstrap/"${deployment_system}"/

if [ ! -d ${terraform_module_directory} ]
then
    echo "#########################################################################################"
    echo "#                                                                                       #" 
    echo "#   Incorrect system deployment type specified :" ${deployment_system} "            #"
    echo "#                                                                                       #" 
    echo "#   Valid options are:                                                                  #"
    echo "#      sap_library                                                                      #"
    echo "#                                                                                       #" 
    echo "#########################################################################################"
    echo ""
    exit -1
fi

ok_to_proceed=false
new_deployment=false

rm backend.tf

reinitialized=0
if [ -f ./backend-config.tfvars ]
then
    terraform_module_directory="${DEPLOYMENT_REPO_PATH}"deploy/terraform/run/"${deployment_system}"/

    echo "#########################################################################################"
    echo "#                                                                                       #" 
    echo "#                          The bootstrapping has already been done!                     #"
    echo "#                                                                                       #" 
    echo "#########################################################################################"
else
    sed -i /REMOTE_STATE_RG/d  "${library_config_information}"
    sed -i /REMOTE_STATE_SA/d  "${library_config_information}"
fi

if [ ! -d ./.terraform/ ]; then
    echo "#########################################################################################"
    echo "#                                                                                       #" 
    echo "#                                   New deployment                                      #"
    echo "#                                                                                       #" 
    echo "#########################################################################################"
    terraform init -upgrade=true "${terraform_module_directory}"
    sed -i /REMOTE_STATE_RG/d  "${library_config_information}"
    sed -i /REMOTE_STATE_SA/d  "${library_config_information}"

else
    if [ $reinitialized -eq 0 ]
    then
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

            terraform init -upgrade=true "{$terraform_module_directory}"
        else
            return 0
        fi
    fi
fi


echo ""
echo "#########################################################################################"
echo "#                                                                                       #" 
echo "#                             Running Terraform plan                                    #"
echo "#                                                                                       #" 
echo "#########################################################################################"
echo ""

if [ -n "${deployer_statefile_foldername}" ]; then
    echo "Deployer folder specified: "${deployer_statefile_foldername}
    terraform plan -var-file="${parameterfile}" -var deployer_statefile_foldername="${deployer_statefile_foldername}" "${terraform_module_directory}" 
else
    terraform plan -var-file="${parameterfile}" "${terraform_module_directory}"
fi

echo ""
echo "#########################################################################################"
echo "#                                                                                       #" 
echo "#                             Running Terraform apply                                   #"
echo "#                                                                                       #" 
echo "#########################################################################################"
echo ""

if [ -n "${deployer_statefile_foldername}" ]; then
    terraform apply ${approve} -var-file="${parameterfile}" -var deployer_statefile_foldername="${deployer_statefile_foldername}" "${terraform_module_directory}"
else
    terraform apply ${approve} -var-file="${parameterfile}" "${terraform_module_directory}"
fi

cat <<EOF > backend.tf
####################################################
# To overcome terraform issue                      #
####################################################
terraform {
    backend "local" {}
}
EOF

REMOTE_STATE_RG=$(terraform output remote_state_resource_group_name | tr -d \")
temp=$(echo "${REMOTE_STATE_RG}" | grep "Warning")
if [ -z "${temp}" ]
then
    temp=$(echo "${REMOTE_STATE_RG}" | grep "Backend reinitialization required")
    if [ -z "${temp}" ]
    then
        sed -i /REMOTE_STATE_RG/d  "${library_config_information}"
        echo "REMOTE_STATE_RG=${REMOTE_STATE_RG}" >> "${library_config_information}"
    fi
fi

REMOTE_STATE_SA=$(terraform output remote_state_storage_account_name| tr -d \")
temp=$(echo "${REMOTE_STATE_SA}" | grep "Warning")
if [ -z "${temp}" ]
then
    temp=$(echo "${REMOTE_STATE_SA}" | grep "Backend reinitialization required")
    if [ -z "${temp}" ]
    then
        sed -i /REMOTE_STATE_SA/d  "${library_config_information}"
        echo "REMOTE_STATE_SA=${REMOTE_STATE_SA}" >> ${library_config_information}
    fi
fi

tfstate_resource_id=$(terraform output tfstate_resource_id| tr -d \")
temp=$(echo "${tfstate_resource_id}" | grep "Warning")
if [ -z "${temp}" ]
then
    temp=$(echo $tfstate_resource_id | grep "Backend reinitialization required")
    if [ -z $temp ]
    then
        sed -i /tfstate_resource_id/d  "${library_config_information}"
        echo "tfstate_resource_id=${tfstate_resource_id}" >> "${library_config_information}"
    fi
fi

rm backend.tf
exit 0