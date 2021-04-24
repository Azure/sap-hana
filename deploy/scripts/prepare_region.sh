#!/bin/bash

. "$(dirname "${BASH_SOURCE[0]}")/deploy_utils.sh"

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
    echo "#    -h Show help                                                                       #"
    echo "#                                                                                       #"
    echo "#   Example:                                                                            #"
    echo "#                                                                                       #"
    echo "#   [REPO-ROOT]deploy/scripts/install_environment.sh \                                  #"
    echo "#      -d DEPLOYER/PROD-WEEU-DEP00-INFRASTRUCTURE/PROD-WEEU-DEP00-INFRASTRUCTURE.json \ #"
    echo "#      -l LIBRARY/PROD-WEEU-SAP_LIBRARY/PROD-WEEU-SAP_LIBRARY.json \                    #"
    echo "#                                                                                       #"
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
    echo "#   Usage: prepare_region.sh                                                            #"
    echo "#      -d deployer parameter file                                                       #"
    echo "#      -l library parameter file                                                        #"
    echo "#      -s subscription (optional)                                                       #"
    echo "#      -c SPN app id (optional)                                                         #"
    echo "#      -p SPN password (optional)                                                       #"
    echo "#      -t tenant id of SPN (optional)                                                   #"
    echo "#      -h Show help                                                                     #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    
}

interactive=0
force=0
subscription=""
client_id=""
spn_secret=""
tenant_id=""

while getopts ":d:l:s:c:p:t:h:f:i" option; do
    case "${option}" in
        d) deployer_parameter_file=${OPTARG};;
        l) library_parameter_file=${OPTARG};;
        f) force=1 ;;
        i) interactive=1 ;;
        s) subscription=${OPTARG};;
        c) client_id=${OPTARG};;
        p) spn_secret=${OPTARG};;
        t) tenant_id=${OPTARG};;
        h) showhelp exit 3 ;;
        ?) echo "Invalid option: -${OPTARG}." exit 2 ;;
    esac
done

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
    echo "#                           Please install Terraform                                    #"
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
    echo "#                           Please install the Azure CLI                                #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    exit -1
fi

# Helper variables
environment=$(cat "${deployer_parameter_file}" | jq .infrastructure.environment | tr -d \")
region=$(cat "${deployer_parameter_file}" | jq .infrastructure.region | tr -d \")

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
    exit -1
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
    exit -1
fi

automation_config_directory=~/.sap_deployment_automation/
generic_config_information="${automation_config_directory}"config
deployer_config_information="${automation_config_directory}""${environment}""${region}"

#Plugins
if [ ! -d "$HOME/.terraform.d/plugin-cache" ]
then
    mkdir "$HOME/.terraform.d/plugin-cache"
fi
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"

root_dirname=$(pwd)

if [ $force == 1 ]
then
    if [ -f "${deployer_config_information}" ]
    then
        rm "${deployer_config_information}"
    fi
fi

init "${automation_config_directory}" "${generic_config_information}" "${deployer_config_information}"

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
    exit -1
fi

templen=$(echo "${ARM_SUBSCRIPTION_ID}" | wc -c)
# Subscription length is 37
if [ 37 != $templen ]
then
    arm_config_stored=0
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
    if [ "{$arm_config_stored}" != 0 ]
    then
        echo "Storing the configuration"
        save_config_var "ARM_SUBSCRIPTION_ID" "${deployer_config_information}"
    fi
fi

deployer_dirname=$(dirname "${deployer_parameter_file}")
deployer_file_parametername=$(basename "${deployer_parameter_file}")

deployer_key=$(echo "${deployer_file_parametername}" | cut -d. -f1)

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
    exit -1
else
    if [ -f stdout.az ]
    then
        rm stdout.az
    fi
fi

step=0
load_config_vars "${deployer_config_information}" "step"

curdir=$(pwd)

if [ 0 == $step ]
then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#                           Bootstrapping the deployer                                  #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    
    cd "${deployer_dirname}"
    
    if [ $force == 1 ]
    then
        if [ -d ./.terraform/ ]; then
            rm .terraform -r
        fi
        
        if [ -f terraform.tfstate ]; then
            rm terraform.tfstate
        fi
        
        if [ -f terraform.tfstate.backup ]; then
            rm terraform.tfstate.backup
        fi
    fi
    
    "${DEPLOYMENT_REPO_PATH}"deploy/scripts/install_deployer.sh -p $deployer_file_parametername -i true
    if [ $? -eq 255 ]
    then
        exit $?
    fi

    save_config_var "step" "${deployer_config_information}"

    if [ ! -z $subscription ]
    then
        save_config_var "subscription" "${deployer_config_information}"
    fi

    if [ ! -z $client_id ]
    then
        save_config_var "client_id" "${deployer_config_information}"
    fi

    if [ ! -z $tenant_id ]
    then
        save_config_var "tenant_id" "${deployer_config_information}"
    fi

    step=1
    save_config_var "step" "${deployer_config_information}"
else
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#                           Deployer is bootstrapped                                    #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
fi

unset TF_DATA_DIR

if [ 1 == $step ]
then
    load_config_vars "${deployer_config_information}" "keyvault"
    if [ ! -z $keyvault ]
    then
        # Key vault was specified in ~/.sap_deployment_automation in the deployer file
        keyvault_param=$(printf " -v %s " "${keyvault}")
    fi
    
    env_param=$(printf " -e %s " "${environment}")
    region_param=$(printf " -r %s " "${region}")

    secretname="${environment}"-client-id
    az keyvault secret show --name $secretname --vault $keyvault 2>error.log > kv.log
    if [ -f error.log ]
    then
        if [ grep "ERROR:" error.log ]
        then
            if [ ! -z $spn_secret ]
            then
                secret_param=$(printf " -s %s " "${spn_secret}")
                allParams="${env_param}""${keyvault_param}""${region_param}""${secret_param}"
                
                "${DEPLOYMENT_REPO_PATH}"deploy/scripts/set_secrets.sh $allParams
                if [ $? -eq 255 ]
                then
                    exit $?
                fi
            else
                read -p -r "Do you want to specify the SPN Details Y/N?"  ans
                answer=${ans^^}
                if [ $answer == 'Y' ]; then
                    
                    allParams="${env_param}""${keyvault_param}""${region_param}"
                    
                    "${DEPLOYMENT_REPO_PATH}"deploy/scripts/set_secrets.sh $allParams
                    if [ $? -eq 255 ]
                    then
                        exit $?
                    fi
                fi
            fi
        fi
    
    if [ -f post_deployment.sh ]; then
        "./post_deployment.sh"
    fi
    cd "${curdir}"
    step=2
    save_config_var "step" "${deployer_config_information}"
fi

unset TF_DATA_DIR

if [ 2 == $step ]
then
    
    
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#                           Bootstrapping the library                                   #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    
    relative_path="${root_dirname}"/"${library_dirname}"
    export TF_DATA_DIR="${relative_path}/.terraform"
    relative_path="${root_dirname}"/"${deployer_dirname}"
    
    cd "${library_dirname}"
    if [ $force == 1 ]
    then
        if [ -d ./.terraform/ ]; then
            rm .terraform -r
        fi
        
        if [ -f terraform.tfstate ]; then
            rm terraform.tfstate
        fi
        
        if [ -f terraform.tfstate.backup ]; then
            rm terraform.tfstate.backup
        fi
    fi
    "${DEPLOYMENT_REPO_PATH}"deploy/scripts/install_library.sh -p "${library_file_parametername}" -i true -d "${relative_path}"
    if [ $? -eq 255 ]
    then
        exit $?
    fi
    cd "${curdir}"
    step=3
    save_config_var "step" "${deployer_config_information}"
else
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#                            Library is bootstrapped                                    #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    
fi

unset TF_DATA_DIR

if [ 3 == $step ]
then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#                           Migrating the deployer state                                #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    
    cd "${deployer_dirname}"
    
    # Remove the script file
    if [ -f post_deployment.sh ]
    then
        rm post_deployment.sh
    fi
    "${DEPLOYMENT_REPO_PATH}"deploy/scripts/installer.sh -p $deployer_file_parametername -i true -t sap_deployer
    if [ $? -eq 255 ]
    then
        exit $?
    fi
    cd "${curdir}"
    step=4
    save_config_var "step" "${deployer_config_information}"
fi

unset TF_DATA_DIR

if [ 4 == $step ]
then
    
    echo ""
    
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#                           Migrating the library state                                 #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    
    cd "${library_dirname}"
    "${DEPLOYMENT_REPO_PATH}"deploy/scripts/installer.sh -p $library_file_parametername  -i true -t sap_library
    if [ $? -eq 255 ]
    then
        exit $?
    fi
    cd "${curdir}"
    step=5
    save_config_var "step" "${deployer_config_information}"
fi
unset TF_DATA_DIR
