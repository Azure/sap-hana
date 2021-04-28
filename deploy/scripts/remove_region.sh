#!/bin/bash

#error codes include those from /usr/include/sysexits.h

#colors for terminal
boldreduscore="\e[1;4;31m"
boldred="\e[1;31m"
cyan="\e[1;36m"
resetformatting="\e[0m"

#External helper functions
#. "$(dirname "${BASH_SOURCE[0]}")/deploy_utils.sh"
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"

#call stack has full scriptname when using source 
source "${script_directory}/deploy_utils.sh"

################################################################################################
#                                                                                              #
#   This file contains the logic to deploy the environment to support SAP workloads.           #
#                                                                                              #
#   The script is intended to be run from a parent folder to the folders containing            #
#   the json parameter files for the deployer, the library and the environment.                #
#                                                                                              #
#   The script will persist the parameters needed between the executions in the                #
#   ~/.sap_deployment_automation folder                                                        #
#                                                                                              #
#   The script experts the following exports:                                                  #
#   ARM_SUBSCRIPTION_ID to specify which subscription to deploy to                             #
#   DEPLOYMENT_REPO_PATH the path to the folder containing the cloned sap-hana                 #
#                                                                                              #
################################################################################################

function showhelp {
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#                                                                                       #"
    echo "#   This file contains the logic to prepare an Azure region to support the              #"
    echo "#   SAP Deployment Automation by preparing the deployer and the library.                #"
    echo "#   The script experts the following exports:                                           #"
    echo "#                                                                                       #"
    echo "#     ARM_SUBSCRIPTION_ID to specify which subscription to deploy to                    #"
    echo "#     DEPLOYMENT_REPO_PATH the path to the folder containing the cloned sap-hana        #"
    echo "#                                                                                       #"
    echo "#   The script is to be run from a parent folder to the folders containing              #"
    echo "#   the json parameter files for the deployer, the library and the environment.         #"
    echo "#                                                                                       #"
    echo "#   The script will persist the parameters needed between the executions in the         #"
    echo "#   ~/.sap_deployment_automation folder                                                 #"
    echo "#                                                                                       #"
    echo "#                                                                                       #"
    echo "#   Usage: prepare_region.sh                                                            #"
    echo "#    -d deployer parameter file                                                         #"
    echo "#    -l library parameter file                                                          #"
    echo "#                                                                                       #"
    echo "#   Optional parameters                                                                 #"
    echo "#    -s subscription                                                                    #"
    echo "#    -c Service Principal Application ID                                                #"
    echo "#    -p Password of the Service Principal                                               #"
    echo "#    -t tenant of the Service Principal                                                 #"
    echo "#    -f Clean up the local Terraform files. Use with caution                            #"
    echo "#    -i Silent install                                                                  #"
    echo "#    -h Show help                                                                       #"
    echo "#                                                                                       #"
    echo "#   Example:                                                                            #"
    echo "#                                                                                       #"
    echo "#   DEPLOYMENT_REPO_PATH/scripts/install_environment.sh \                               #"
    echo "#      -d DEPLOYER/PROD-WEEU-DEP00-INFRASTRUCTURE/PROD-WEEU-DEP00-INFRASTRUCTURE.json \ #"
    echo "#      -l LIBRARY/PROD-WEEU-SAP_LIBRARY/PROD-WEEU-SAP_LIBRARY.json \                    #"
    echo "#                                                                                       #"
    echo "#   Example:                                                                            #"
    echo "#                                                                                       #"
    echo "#   DEPLOYMENT_REPO_PATH/scripts/install_environment.sh \                               #"
    echo "#      -d DEPLOYER/PROD-WEEU-DEP00-INFRASTRUCTURE/PROD-WEEU-DEP00-INFRASTRUCTURE.json \ #"
    echo "#      -l LIBRARY/PROD-WEEU-SAP_LIBRARY/PROD-WEEU-SAP_LIBRARY.json \                    #"
    echo "#      -s xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx                                          #"
    echo "#      -c yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy                                          #"
    echo "#      -p ************************                                                      #"  
    echo "#      -t zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz                                          #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
}

function missing {
    printf -v val '%-40s' "$missing_value"
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#   Missing : ${val}                                  #"
    echo "#                                                                                       #"
    echo "#   Usage: remove_region.sh                                                            #"
    echo "#      -d deployer parameter file                                                       #"
    echo "#      -l library parameter file                                                        #"
    echo "#      -s subscription                                                                  #"
    echo "#      -b storage account name (terrafrom state file)                                   #"
    echo "#      -h Show help                                                                     #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    
}

force=0

INPUT_ARGUMENTS=$(getopt -n remove_region -o d:l:s:b:r:h --longoptions deployer_parameter_file:,library_parameter_file:,subscription:,resource_group:, storage_account:,help -- "$@")
VALID_ARGUMENTS=$?

if [ "$VALID_ARGUMENTS" != "0" ]; then
  showhelp
fi

eval set -- "$INPUT_ARGUMENTS"
while :
do
  case "$1" in
    -d | --deployer_parameter_file)            deployer_parameter_file="$2"     ; shift 2 ;;
    -l | --library_parameter_file)             library_parameter_file="$2"      ; shift 2 ;;
    -b | --storage_account)                    storage_account="$2"             ; shift 2 ;;
    -r | --resource_group)                     resource_group="$2"              ; shift 2 ;;
    -h | --help)                               showhelp 
                                               exit 3                           ; shift ;;
    --) shift; break ;;
  esac
done


if [ ! -z "$approve" ]; then
    approveparam=" -i"
fi

if [ -z "$deployer_parameter_file" ]; then
    missing_value='deployer parameter file'
    missing
    exit -1
fi

if [ -z "$library_parameter_file" ]; then
    missing_value='library parameter file'
    missing
    exit -1
fi

# Check terraform
tf=$(terraform -version | grep Terraform)
if [ ! -n "$tf" ]; then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                          $boldreduscore  Please install Terraform $resetformatting                                 #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    exit -1
fi

az --version > stdout.az 2>&1
az=$(grep "azure-cli" stdout.az)
if [ ! -n "${az}" ]; then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                          $boldreduscore Please install the Azure CLI $resetformatting                               #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    exit -1
fi

# Helper variables
environment=$(jq .infrastructure.environment "${deployer_parameter_file}" | tr -d \")
region=$(jq .infrastructure.region "${deployer_parameter_file}" | tr -d \")
key=$(echo "${deployer_parameter_file}" | cut -d. -f1)

if [ ! -n "${environment}" ]
then
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#                           Incorrect parameter file.                                   #"
    echo "#                                                                                       #"
    echo "#     The file needs to contain the infrastructure.environment attribute!!              #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    exit 64 #script usage wrong
fi

if [ ! -n "${region}" ]
then
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#                           Incorrect parameter file.                                   #"
    echo "#                                                                                       #"
    echo "#       The file needs to contain the infrastructure.region attribute!!                 #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    exit 64 #script usage wrong
fi

automation_config_directory=~/.sap_deployment_automation/
generic_config_information="${automation_config_directory}"config
deployer_config_information="${automation_config_directory}""${environment}""${region}"

if [ -z "$deployer_config_information" ]; then
    rm $deployer_config_information
fi

#Plugins
if [ ! -d "$HOME/.terraform.d/plugin-cache" ]
then
    mkdir "$HOME/.terraform.d/plugin-cache"
fi
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"

root_dirname=$(pwd)

init "${automation_config_directory}" "${generic_config_information}" "${deployer_config_information}"

if [ ! -z "${subscription}" ]
then
    export ARM_SUBSCRIPTION_ID=$subscription
fi

if [ ! -n "$DEPLOYMENT_REPO_PATH" ]; then
    echo ""
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
    exit 65 #data format error
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
    exit 65 #data format error
fi

deployer_dirname=$(dirname "${deployer_parameter_file}")
deployer_file_parametername=$(basename "${deployer_parameter_file}")

library_dirname=$(dirname "${library_parameter_file}")
library_file_parametername=$(basename "${library_parameter_file}")

relative_path="${root_dirname}"/"${deployer_dirname}"
export TF_DATA_DIR="${relative_path}"/.terraform
# Checking for valid az session

temp=$(grep "az login" stdout.az)
if [ -n "${temp}" ]; then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#                           Please login using az login                                 #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    if [ -f stdout.az ]
    then
        rm stdout.az
    fi
    exit 67 #addressee unknown
else
    if [ -f stdout.az ]
    then
        rm stdout.az
    fi

    if [ ! -z "${subscription}" ]
    then
        az account set --sub "${subscription}"
    fi

fi

curdir=$(pwd)


# Deployer

cd "${deployer_dirname}" || exit

param_dirname=$(pwd)

terraform_module_directory="${DEPLOYMENT_REPO_PATH}"deploy/terraform/run/sap_deployer/
export TF_DATA_DIR="${param_dirname}/.terraform"

#Reinitialize

terraform -chdir="${terraform_module_directory}" init -upgrade=true \
--backend-config "subscription_id=${subscription}" \
--backend-config "resource_group_name=${resource_group}" \
--backend-config "storage_account_name=${storage_Account}" \
--backend-config "container_name=tfstate" \
--backend-config "key=${key}.terraform.tfstate"


#Initialize the statefile and copy to local
terraform_module_directory="${DEPLOYMENT_REPO_PATH}"deploy/terraform/bootstrap/sap_deployer/
terraform -chdir="${terraform_module_directory}" init force-copy -backend-config "path=${param_dirname}/terraform.tfstate"

cd "${curdir}" || exit

key=$(echo "${library_parameter_file}" | cut -d. -f1)
cd "${library_dirname}" || exit
param_dirname=$(pwd)

#Library

terraform_module_directory="${DEPLOYMENT_REPO_PATH}"deploy/terraform/run/sap_library/
export TF_DATA_DIR="${param_dirname}/.terraform"

#Reinitialize

terraform -chdir="${terraform_module_directory}" init -upgrade=true \
--backend-config "subscription_id=${subscription}" \
--backend-config "resource_group_name=${resource_group}" \
--backend-config "storage_account_name=${storage_Account}" \
--backend-config "container_name=tfstate" \
--backend-config "key=${key}.terraform.tfstate"


#Initialize the statefile and copy to local
terraform_module_directory="${DEPLOYMENT_REPO_PATH}"deploy/terraform/bootstrap/sap_library/
terraform -chdir="${terraform_module_directory}" init force-copy -backend-config "path=${param_dirname}/terraform.tfstate"

terraform -chdir="${terraform_module_directory}" destroy 

cd "${curdir}" || exit

cd "${deployer_dirname}" || exit

param_dirname=$(pwd)

terraform_module_directory="${DEPLOYMENT_REPO_PATH}"deploy/terraform/run/sap_deployer/
export TF_DATA_DIR="${param_dirname}/.terraform"

terraform -chdir="${terraform_module_directory}" destroy 

cd "${curdir}" || exit


unset TF_DATA_DIR

exit 0