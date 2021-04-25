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

#Internal helper functions
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

while getopts "p:d:ih" option; do
    case "${option}" in
        p) parameterfile=${OPTARG};;
        i) approve="--auto-approve" ;;
        d) deployer_statefile_foldername=${OPTARG};;
        h) showhelp
            exit 3
        ;;
        ?) echo "Invalid option: -${OPTARG}."
            exit 2
        ;;
    esac
done

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

if [ ! -d "${deployer_statefile_foldername}" ]
then
    printf -v val %-40.40s "$deployer_statefile_foldername"
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#                    Directory does not exist:  "${deployer_statefile_foldername}" #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    exit
fi


param_dirname=$(dirname "${parameterfile}")

if [ $param_dirname != '.' ]; then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#   Please run this command from the folder containing the parameter file               #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    exit 3
fi

# Read environment
environment=$(cat "${parameterfile}" | jq .infrastructure.environment | tr -d \")
region=$(cat "${parameterfile}" | jq .infrastructure.region | tr -d \")
key=$(echo "${parameterfile}" | cut -d. -f1)

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

#Persisting the parameters across executions
automation_config_directory=~/.sap_deployment_automation/
generic_config_information="${automation_config_directory}"config
library_config_information="${automation_config_directory}""${environment}""${region}"

arm_config_stored=false
config_stored=false

param_dirname=$(pwd)

init "${automation_config_directory}" "${generic_config_information}" "${library_config_information}"

export TF_DATA_DIR="${param_dirname}"/.terraform
var_file="${param_dirname}"/"${parameterfile}" 

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
fi

templen=$(echo "${ARM_SUBSCRIPTION_ID}" | wc -c)
# Subscription length is 37
if [ 37 != $templen ]
then
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

if [ -f backend.tf ]
then
    rm backend.tf
fi

reinitialized=0

if [ -f ./backend-config.tfvars ]
then
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#                        The bootstrapping has already been done!                       #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
else
    sed -i /REMOTE_STATE_RG/d  "${library_config_information}"
    sed -i /REMOTE_STATE_SA/d  "${library_config_information}"
    sed -i /tfstate_resource_id/d  "${library_config_information}"
fi

if [ ! -d ./.terraform/ ]; then
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#                                   New deployment                                      #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    terraform -chdir="${terraform_module_directory}" init -upgrade=true -backend-config "path=${param_dirname}/terraform.tfstate"
    sed -i /REMOTE_STATE_RG/d  "${library_config_information}"
    sed -i /REMOTE_STATE_SA/d  "${library_config_information}"
    sed -i /tfstate_resource_id/d  "${library_config_information}"
    
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
                    exit 0
                fi
            fi
            terraform -chdir="${terraform_module_directory}" init -upgrade=true -reconfigure -backend-config "path=${param_dirname}/terraform.tfstate"
        else
            exit 0
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
    echo "Deployer folder specified:" "${deployer_statefile_foldername}"
    terraform -chdir="${terraform_module_directory}" plan -no-color -var-file="${var_file}" -var deployer_statefile_foldername="${deployer_statefile_foldername}" > plan_output.log 2>&1
else
    terraform -chdir="${terraform_module_directory}" plan -no-color -var-file="${var_file}"  > plan_output.log 2>&1
fi

str1=$(grep "Error: KeyVault " plan_output.log)

if [ -n "${str1}" ]; then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                          $boldreduscore Errors during the plan phase $resetformatting                                #"    
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    echo $str1
    rm plan_output.log
    exit -1
fi

if [ -f plan_output.log ]; then
    rm plan_output.log
fi

echo ""
echo "#########################################################################################"
echo "#                                                                                       #"
echo "#                             Running Terraform apply                                   #"
echo "#                                                                                       #"
echo "#########################################################################################"
echo ""

if [ -n "${deployer_statefile_foldername}" ]; 
then
    echo "Deployer folder specified:" "${deployer_statefile_foldername}"
    terraform -chdir="${terraform_module_directory}" apply ${approve} -var-file="${var_file}" -var deployer_statefile_foldername="${deployer_statefile_foldername}" 2>error.log
else
    terraform -chdir="${terraform_module_directory}" apply ${approve} -var-file="${var_file}" 2>error.log
fi
 
str1=$(grep "Error: " error.log)
if [ -n "${str1}" ]
then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                          $boldreduscore Errors during the apply phase $resetformatting                              #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    cat error.log
    rm error.log
    unset TF_DATA_DIR
    exit -1
fi
return_value=-1

REMOTE_STATE_SA=$(terraform -chdir="${terraform_module_directory}" output remote_state_storage_account_name| tr -d \")
temp=$(echo "${REMOTE_STATE_SA}" | grep -m1 "Warning")
if [ -z "${temp}" ]
then
    temp=$(echo "${REMOTE_STATE_SA}" | grep "Backend reinitialization required")
    if [ -z "${temp}" ]
    then
        REMOTE_STATE_RG=$(az resource list --name ${REMOTE_STATE_SA} | jq .[0].resourceGroup  | tr -d \" | xargs)
        tfstate_resource_id=$(az resource list --name ${REMOTE_STATE_SA} | jq .[0].id  | tr -d \" | xargs)
        STATE_SUBSCRIPTION=$(echo $tfstate_resource_id | cut -d/ -f3 | tr -d \" | xargs)
        
        save_config_vars "${library_config_information}" \
            REMOTE_STATE_RG \
            REMOTE_STATE_SA \
            tfstate_resource_id \
            STATE_SUBSCRIPTION
        
        return_value=0
    fi
fi

exit $return_value