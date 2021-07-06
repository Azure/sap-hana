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
    echo -e "#                 $boldreduscore !Warning!: This script will remove deployed systems $resetformatting                 #"
    echo "#                                                                                       #"
    echo "#   This file contains the logic to remove the different systems                        #"
    echo "#   The script expects the following exports:                                           #"
    echo "#                                                                                       #"
    echo "#      DEPLOYMENT_REPO_PATH (path to the repo folder (sap-hana))                        #"
    echo "#      ARM_SUBSCRIPTION_ID (subscription containing the state file storage account)     #"
    echo "#      REMOTE_STATE_RG (resource group name for storage account containing state files) #"
    echo "#      REMOTE_STATE_SA (storage account for state file)                                 #"
    echo "#                                                                                       #"
    echo "#   The script will persist the parameters needed between the executions in the         #"
    echo "#   ~/.sap_deployment_automation folder.                                                #"
    echo "#                                                                                       #"
    echo "#                                                                                       #"
    echo "#   Usage: remover.sh                                                                   #"
    echo "#    -p or --parameterfile                parameter file                                #"
    echo "#    -t or --type                         type of system to remove                      #"
    echo "#                                         valid options:                                #"
    echo "#                                           sap_deployer                                #"
    echo "#                                           sap_library                                 #"
    echo "#                                           sap_landscape                               #"
    echo "#                                           sap_system                                  #"
    echo "#    -h or --help                    Show help                                          #"
    echo "#                                                                                       #"
    echo "#   Example:                                                                            #"
    echo "#                                                                                       #"
    echo "#   [REPO-ROOT]deploy/scripts/remover.sh \                                              #"
    echo "#      --parameterfile DEV-WEEU-SAP01-X00.json \                                        #"
    echo "#      --type sap_system                                                                #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
}

function missing {
    printf -v val %-.40s "$option"
    echo ""
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#   Missing environment variables: ${option}!!!              #"
    echo "#                                                                                       #"
    echo "#   Please export the folloing variables:                                               #"
    echo "#      DEPLOYMENT_REPO_PATH (path to the repo folder (sap-hana))                        #"
    echo "#      ARM_SUBSCRIPTION_ID (subscription containing the state file storage account)     #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
}

#process inputs - may need to check the option i for auto approve as it is not used
INPUT_ARGUMENTS=$(getopt -n validate -o p:t:hi --longoptions type:,parameterfile:,auto-approve,help -- "$@")
VALID_ARGUMENTS=$?

if [ "$VALID_ARGUMENTS" != "0" ]; then
  showhelp
fi

eval set -- "$INPUT_ARGUMENTS"
while :
do
  case "$1" in
    -p | --parameterfile)                      parameterfile="$2"               ; shift 2 ;;
    -t | --type)                               deployment_system="$2"           ; shift 2 ;;
    -i | --auto-approve)                       approve="--auto-approve"         ; shift ;;
    -h | --help)                               showhelp 
                                               exit 3                           ; shift ;;
    --) shift; break ;;
  esac
done

#variables
tfstate_resource_id=""
tfstate_parameter=""
deployer_tfstate_key=""
deployer_tfstate_key_parameter=""
landscape_tfstate_key=""
landscape_tfstate_key_parameter=""

# unused variables
#show_help=false
#deployer_tfstate_key_exists=false
#landscape_tfstate_key_exists=false
working_directory=$(pwd)
parameterfile_path=$(realpath "${parameterfile}")
parameterfile_name=$(basename "${parameterfile_path}")
parameterfile_dirname=$(dirname "${parameterfile_path}")

if [ "${parameterfile_dirname}" != "${working_directory}" ]; then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#  $boldred Please run this command from the folder containing the parameter file $resetformatting              #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    exit 3
fi

if [ ! -n "${deployment_system}" ]; then
    printf -v val %-40.40s "$deployment_system"
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "# $boldred Incorrect system deployment type specified: ${val} $resetformatting #"
    echo "#                                                                                       #"
    echo "#     Valid options are:                                                                #"
    echo "#       sap_deployer                                                                    #"
    echo "#       sap_library                                                                     #"
    echo "#       sap_landscape                                                                   #"
    echo "#       sap_system                                                                      #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    exit 64 #script usage wrong
fi

# Read environment
environment=$(jq --raw-output .infrastructure.environment "${parameterfile}")
region=$(jq --raw-output .infrastructure.region "${parameterfile}")

if [ ! -n "${environment}" ]; then
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#                           Incorrect parameter file.                                   #"
    echo "#                                                                                       #"
    echo "#     The file needs to contain the infrastructure.environment attribute!!              #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    exit 65 #data format error
fi

if [ ! -n "${region}" ]; then
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#                           Incorrect parameter file.                                   #"
    echo "#                                                                                       #"
    echo "#       The file needs to contain the infrastructure.region attribute!!                 #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    exit 65 #data format error
fi


if [ ! -f "${parameterfile}" ]; then
    printf -v val %-40.40s "$parameterfile"
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#               Parameter file does not exist: ${val} #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    exit 2 #No such file or directory
fi

#Persisting the parameters across executions
automation_config_directory="$HOME/.sap_deployment_automation/"
generic_config_information="${automation_config_directory}"config
system_config_information="${automation_config_directory}""${environment}""${region}"

key=$(echo "${parameterfile}" | cut -d. -f1)


#Plugins
if [ ! -d "$HOME/.terraform.d/plugin-cache" ]; then
    mkdir "$HOME/.terraform.d/plugin-cache"
fi
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"

#root_dirname=$(pwd)
#parameterfile_dirname=$(pwd) <- this would not be necessary we validate this above

init "${automation_config_directory}" "${generic_config_information}" "${system_config_information}"
var_file="${parameterfile_dirname}"/"${parameterfile}"

load_config_vars "${system_config_information}" "REMOTE_STATE_SA"
load_config_vars "${system_config_information}" "REMOTE_STATE_RG"
load_config_vars "${system_config_information}" "tfstate_resource_id"
load_config_vars "${system_config_information}" "deployer_tfstate_key"
load_config_vars "${system_config_information}" "landscape_tfstate_key"
load_config_vars "${system_config_information}" "STATE_SUBSCRIPTION"
load_config_vars "${system_config_information}" "ARM_SUBSCRIPTION_ID"

deployer_tfstate_key_parameter=''
if [ "${deployment_system}" != sap_deployer ]; then
    deployer_tfstate_key_parameter=" -var deployer_tfstate_key=${deployer_tfstate_key}"
fi

landscape_tfstate_key_parameter=''
if [ "${deployment_system}" == sap_system ]; then
    landscape_tfstate_key_parameter=" -var landscape_tfstate_key=${landscape_tfstate_key}"
fi

tfstate_parameter=" -var tfstate_resource_id=${tfstate_resource_id}"

if [ ! -n "${DEPLOYMENT_REPO_PATH}" ]; then
    option="DEPLOYMENT_REPO_PATH"
    missing
    exit -1
fi

# Checking for valid az session
az account show >stdout.az 2>&1
temp=$(grep "az login" stdout.az)
if [ -n "${temp}" ]; then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#                           Please login using az login                                 #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    if [ -f stdout.az ]; then
        rm stdout.az
    fi
    exit 67 #addressee unknown
else
    if [ -f stdout.az ]; then
        rm stdout.az
    fi

fi

account_set=0

if [ ! -z "${STATE_SUBSCRIPTION}" ]; then
    $(az account set --sub "${STATE_SUBSCRIPTION}")
    account_set=1
fi

export TF_DATA_DIR="${parameterfile_dirname}"/.terraform

terraform_module_directory="${DEPLOYMENT_REPO_PATH}"/deploy/terraform/run/"${deployment_system}"/

if [ ! -d "${terraform_module_directory}" ]; then
    printf -v val %-40.40s "$deployment_system"
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#   Incorrect system deployment type specified: ${val}#"
    echo "#                                                                                       #"
    echo "#     Valid options are:                                                                #"
    echo "#       sap_deployer                                                                    #"
    echo "#       sap_library                                                                     #"
    echo "#       sap_landscape                                                                   #"
    echo "#       sap_system                                                                      #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    exit 66 #cannot open input file/folder
fi

#ok_to_proceed=false
#new_deployment=false

if [ -f backend.tf ]; then
    rm backend.tf
fi

#check_output=0

echo ""
echo "#########################################################################################"
echo "#                                                                                       #"
echo "#                             Running Terraform init                                    #"
echo "#                                                                                       #"
echo "#########################################################################################"
echo ""



terraform -chdir="${terraform_module_directory}" init -upgrade=true -reconfigure \
--backend-config "subscription_id=${STATE_SUBSCRIPTION}" \
--backend-config "resource_group_name=${REMOTE_STATE_RG}" \
--backend-config "storage_account_name=${REMOTE_STATE_SA}" \
--backend-config "container_name=tfstate" \
--backend-config "key=${key}.terraform.tfstate"

echo ""
echo "#########################################################################################"
echo "#                                                                                       #"
echo "#                             Running Terraform destroy                                 #"
echo "#                                                                                       #"
echo "#########################################################################################"
echo ""

#TODO:
#create retire_region.sh for deleting the deployer and the library in a proper way
#terraform doesn't seem to tokenize properly when we pass a full string
if [ "$deployment_system" == "sap_deployer" ]; then
    echo -e "#$cyan processing $deployment_system removal as defined in $parameterfile_name $resetformatting"
    terraform -chdir="${terraform_module_directory}" destroy -var-file="${var_file}" \
        $landscape_tfstate_key_parameter \
        $deployer_tfstate_key_parameter

elif [ "$deployment_system" == "sap_library" ]; then
    echo -e "#$cyan processing $deployment_system removal as defined in $parameterfile_name $resetformatting"

    terraform_bootstrap_directory="${DEPLOYMENT_REPO_PATH}/deploy/terraform/bootstrap/${deployment_system}/"
    if [ ! -d "${terraform_bootstrap_directory}" ]; then
        printf -v val %-40.40s "$terraform_bootstrap_directory"
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo "#   Unable to find bootstrap directory: ${val}#"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""
        exit 66 #cannot open input file/folder
    fi
    terraform -chdir="${terraform_bootstrap_directory}" init -upgrade=true -force-copy

    terraform -chdir="${terraform_bootstrap_directory}" destroy -var-file="${var_file}" \
        $landscape_tfstate_key_parameter \
        $deployer_tfstate_key_parameter
else
    echo -e "#$cyan processing $deployment_system removal as defined in $parameterfile_name $resetformatting"
    terraform -chdir="${terraform_module_directory}" destroy -var-file="${var_file}" \
        $tfstate_parameter \
        $landscape_tfstate_key_parameter \
        $deployer_tfstate_key_parameter
fi

if [ "${deployment_system}" == sap_deployer ]; then
    sed -i /deployer_tfstate_key/d "${system_config_information}"
fi

if [ "${deployment_system}" == sap_landscape ]; then
    sed -i /landscape_tfstate_key/d "${system_config_information}"
fi

if [ "${deployment_system}" == sap_library ]; then
    sed -i /REMOTE_STATE_RG/d "${system_config_information}"
    sed -i /REMOTE_STATE_SA/d "${system_config_information}"
    sed -i /tfstate_resource_id/d "${system_config_information}"
fi

unset TF_DATA_DIR

exit 0
