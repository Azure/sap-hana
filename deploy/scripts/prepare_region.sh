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
    echo "#################################################################################################################"
    echo "#                                                                                                               #"
    echo "#                                                                                                               #"
    echo "#   This file contains the logic to prepare an Azure region to support the SAP Deployment Automation by         #"
    echo "#    preparing the deployer and the library.                                                                    #"
    echo "#   The script experts the following exports:                                                                   #"
    echo "#                                                                                                               #"
    echo "#     ARM_SUBSCRIPTION_ID to specify which subscription to deploy to                                            #"
    echo "#     DEPLOYMENT_REPO_PATH the path to the folder containing the cloned sap-hana                                #"
    echo "#                                                                                                               #"
    echo "#   The script is to be run from a parent folder to the folders containing the json parameter files for         #"
    echo "#    the deployer and the library and the environment.                                                          #"
    echo "#                                                                                                               #"
    echo "#   The script will persist the parameters needed between the executions in the                                 #"
    echo "#   ~/.sap_deployment_automation folder                                                                         #"
    echo "#                                                                                                               #"
    echo "#                                                                                                               #"
    echo "#   Usage: prepare_region.sh                                                                                    #"
    echo "#      -d or --deployer_parameter_file       deployer parameter file                                            #"
    echo "#      -l or --library_parameter_file        library parameter file                                             #"
    echo "#                                                                                                               #"
    echo "#   Optional parameters                                                                                         #"
    echo "#      -s or --subscription                  subscription                                                       #"
    echo "#      -c or --spn_id                        SPN application id                                                 #"
    echo "#      -p or --spn_secret                    SPN password                                                       #"
    echo "#      -t or --tenant_id                     SPN Tenant id                                                      #"
    echo "#      -f or --force                         Clean up the local Terraform files.                                #"
    echo "#      -i or --auto-approve                  Silent install                                                     #"
    echo "#      -h or --help                          Help                                                               #"
    echo "#                                                                                                               #"
    echo "#   Example:                                                                                                    #"
    echo "#                                                                                                               #"
    echo "#   DEPLOYMENT_REPO_PATH/scripts/prepare_region.sh \                                                            #"
    echo "#      --deployer_parameter_file DEPLOYER/MGMT-WEEU-DEP00-INFRASTRUCTURE/MGMT-WEEU-DEP00-INFRASTRUCTURE.json \  #"
    echo "#      --library_parameter_file LIBRARY/MGMT-WEEU-SAP_LIBRARY/MGMT-WEEU-SAP_LIBRARY.json \                      #"
    echo "#                                                                                                               #"
    echo "#   Example:                                                                                                    #"
    echo "#                                                                                                               #"
    echo "#   DEPLOYMENT_REPO_PATH/scripts/prepare_region.sh \                                                            #"
    echo "#      --deployer_parameter_file DEPLOYER/PROD-WEEU-DEP00-INFRASTRUCTURE/PROD-WEEU-DEP00-INFRASTRUCTURE.json  \ #"
    echo "#      --library_parameter_file LIBRARY/PROD-WEEU-SAP_LIBRARY/PROD-WEEU-SAP_LIBRARY.json \                      #"
    echo "#      --subscription xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \                                                    #"
    echo "#      --spn_id yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy \                                                          #"
    echo "#      --spn_secret ************************ \                                                                  #"  
    echo "#      --tenant_id zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz \                                                       #"
    echo "#      --auto-approve                                                                                           #"  
    echo "#                                                                                                               #"
    echo "#################################################################################################################"
}

function missing {
    printf -v val '%-40s' "$missing_value"
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#   Missing : ${val}                                  #"
    echo "#                                                                                       #"
    echo "#   Usage: prepare_region.sh                                                            #"
    echo "#      -d or --deployer_parameter_file       deployer parameter file                    #"
    echo "#      -l or --library_parameter_file        library parameter file                     #"
    echo "#                                                                                       #"
    echo "#   Optional parameters                                                                 #"
    echo "#      -s or --subscription                  subscription                               #"
    echo "#      -c or --spn_id                        SPN application id                         #"
    echo "#      -p or --spn_secret                    SPN password                               #"
    echo "#      -t or --tenant_id                     SPN Tenant id                              #"
    echo "#      -f or --force                         Clean up the local Terraform files.        #"
    echo "#      -i or --auto-approve                  Silent install                             #"
    echo "#      -h or --help                          Help                                       #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    
}

force=0

INPUT_ARGUMENTS=$(getopt -n prepare_region  -o d:l:s:c:p:t:ifh --longoptions deployer_parameter_file:,library_parameter_file:,subscription:,spn_id:,spn_secret:,tenant_id:,auto-approve,force,help -- "$@")
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
    -s | --subscription)                       subscription="$2"                ; shift 2 ;;
    -c | --spn_id)                             client_id="$2"                   ; shift 2 ;;
    -p | --spn_secret)                         spn_secret="$2"                  ; shift 2 ;;
    -t | --tenant_id)                          tenant_id="$2"                   ; shift 2 ;;
    -f | --force)                              force=1                          ; shift ;;
    -i | --auto-approve)                       approve="--auto-approve"         ; shift ;;
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
environment=$(jq --raw-output .infrastructure.environment "${deployer_parameter_file}")
region=$(jq --raw-output .infrastructure.region "${deployer_parameter_file}")

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
    exit 64                                                                                           #script usage wrong
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

if [ ! -z "${subscription}" ]
then
    ARM_SUBSCRIPTION_ID="${subscription}"
    save_config_var "ARM_SUBSCRIPTION_ID" "${deployer_config_information}"
    save_config_var "subscription" "${deployer_config_information}"
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
    exit 65                                                                                           #data format error
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
    exit 65                                                                                           #data format error
else
    if [ "${arm_config_stored}" != 0 ]
    then
        echo "Storing the configuration"
        save_config_var "ARM_SUBSCRIPTION_ID" "${deployer_config_information}"
    fi
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
    exit 67                                                                                             #addressee unknown
else
    if [ -f stdout.az ]
    then
        rm stdout.az
    fi

    if [ ! -z "${subscription}" ]
    then
        echo "Setting the subscription"
        az account set --sub "${subscription}"
        export ARM_SUBSCRIPTION_ID="${subscription}"
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
    
    cd "${deployer_dirname}" || exit
    
    if [ $force == 1 ]
    then
        # This is a a bit verbose

        # if [ -d ./.terraform/ ]; then
        #     rm .terraform -r
        # fi
        
        # if [ -f terraform.tfstate ]; then
        #     rm terraform.tfstate
        # fi
        
        # if [ -f terraform.tfstate.backup ]; then
        #     rm terraform.tfstate.backup
        # fi
        
        
        
        # Another way to do it
        
        # [ -d .terraform ]               && rm -Rf .terraform
        # [ -f terraform.tfstate ]        && rm     terraform.tfstate
        # [ -f terraform.tfstate.backup ] && rm     terraform.tfstate.backup

        # This is the simplest
        rm -Rf .terraform terraform.tfstate*
    fi
    
    allParams=$(printf " -p %s %s" "${deployer_file_parametername}" "${approveparam}")
                
    "${DEPLOYMENT_REPO_PATH}"/deploy/scripts/install_deployer.sh $allParams
    if (( $? > 0 ))
    then
        exit $?
    fi
    
    step=1
    save_config_var "step" "${deployer_config_information}"
    
    if [ ! -z "$subscription" ]
    then
        save_config_var "subscription" "${deployer_config_information}"
        kvsubscription=$subscription
        save_config_var "kvsubscription" "${deployer_config_information}"
    fi
    
    if [ ! -z "$client_id" ]
    then
        save_config_var "client_id" "${deployer_config_information}"
    fi
    
    if [ ! -z "$tenant_id" ]
    then
        save_config_var "tenant_id" "${deployer_config_information}"
    fi
    
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
    echo "Using the keyvault: " $keyvault
    secretname="${environment}"-client-id
    az keyvault secret show --name "$secretname" --vault "$keyvault" --only-show-errors 2>error.log
    if [ -s error.log ]
    then
        if [ ! -z "$spn_secret" ]
        then
            allParams=$(printf " -e %s -r %s -v %s --spn_secret %s " "${environment}" "${region}" "${keyvault}" "${spn_secret}" )
            
            "${DEPLOYMENT_REPO_PATH}"/deploy/scripts/set_secrets.sh $allParams
            if (( $? > 0 ))
            then
                exit $?
            fi
        else
            read -p  "Do you want to specify the SPN Details Y/N?"  ans
            answer=${ans^^}
            if [ "$answer" == 'Y' ]; then
                
                allParams="${env_param}""${keyvault_param}""${region_param}"
                
                "${DEPLOYMENT_REPO_PATH}"/deploy/scripts/set_secrets.sh $allParams
                if (( $? > 0 ))
                then
                    exit $?
                fi
            fi
        fi
        
        if [ -f post_deployment.sh ]; then
            ./post_deployment.sh
            if (( $? > 0 )); then
                exit $?
            fi
        fi
        cd "${curdir}" || exit
        step=2
        save_config_var "step" "${deployer_config_information}"
    fi
fi
unset TF_DATA_DIR
cd $root_dirname
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
    
    cd "${library_dirname}" || exit
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
    allParams=$(printf " -p %s -d %s %s" "${library_file_parametername}" "${relative_path}" "${approveparam}")
    
    "${DEPLOYMENT_REPO_PATH}"/deploy/scripts/install_library.sh $allParams
    if (( $? > 0 ))
    then
        exit $?
    fi
    cd "${curdir}" || exit
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
    step=3
    save_config_var "step" "${deployer_config_information}"
    
fi

unset TF_DATA_DIR
cd $root_dirname

if [ 3 == $step ]
then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#                           Migrating the deployer state                                #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    
    cd "${deployer_dirname}" || exit
    
    # Remove the script file
    if [ -f post_deployment.sh ]
    then
        rm post_deployment.sh
    fi
    allParams=$(printf " -p %s -t sap_deployer %s" "${deployer_file_parametername}" "${approveparam}")
    
    "${DEPLOYMENT_REPO_PATH}"/deploy/scripts/installer.sh $allParams
    if (( $? > 0 ))
    then
        exit $?
    fi
    cd "${curdir}" || exit
    step=4
    save_config_var "step" "${deployer_config_information}"
fi

unset TF_DATA_DIR
cd $root_dirname

if [ 4 == $step ]
then
    
    echo ""
    
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#                           Migrating the library state                                 #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    
    cd "${library_dirname}" || exit
    allParams=$(printf " -p %s -t sap_library %s" "${library_file_parametername}" "${approveparam}")

    "${DEPLOYMENT_REPO_PATH}"/deploy/scripts/installer.sh $allParams
    if (( $? > 0 ))
    then
        exit $?
    fi
    cd "${curdir}" || exit
    step=3
    save_config_var "step" "${deployer_config_information}"
fi
unset TF_DATA_DIR

exit 0
