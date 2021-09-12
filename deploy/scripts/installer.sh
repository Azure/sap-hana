#!/bin/bash

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

function showhelp {
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#                                                                                       #"
    echo "#   This file contains the logic to deploy the different systems                        #"
    echo "#   The script experts the following exports:                                           #"
    echo "#                                                                                       #"
    echo "#     ARM_SUBSCRIPTION_ID to specify which subscription to deploy to                    #"
    echo "#     DEPLOYMENT_REPO_PATH the path to the folder containing the cloned sap-hana        #"
    echo "#                                                                                       #"
    echo "#   The script will persist the parameters needed between the executions in the         #"
    echo "#   ~/.sap_deployment_automation folder                                                 #"
    echo "#                                                                                       #"
    echo "#                                                                                       #"
    echo "#   Usage: installer.sh                                                                 #"
    echo "#    -p or --parameterfile                parameter file                                #"
    echo "#    -t or --type                         type of system to remove                      #"
    echo "#                                         valid options:                                #"
    echo "#                                           sap_deployer                                #"
    echo "#                                           sap_library                                 #"
    echo "#                                           sap_landscape                               #"
    echo "#                                           sap_system                                  #"
    echo "#                                                                                       #"
    echo "#   Optional parameters                                                                 #"
    echo "#                                                                                       #"
    echo "#    -o or --storageaccountname           Storage account name for state file           #"
    echo "#    -i or --auto-approve                 Silent install                                #"
    echo "#    -h or --help                         Show help                                     #"
    echo "#                                                                                       #"
    echo "#   Example:                                                                            #"
    echo "#                                                                                       #"
    echo "#   [REPO-ROOT]deploy/scripts/installer.sh \                                            #"
    echo "#      --parameterfile DEV-WEEU-SAP01-X00 \                                             #"
    echo "#      --type sap_system                                                                #"
    echo "#      --auto-approve                                                                   #"
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
    echo "#      REMOTE_STATE_RG (resource group name for storage account containing state files) #"
    echo "#      REMOTE_STATE_SA (storage account for state file)                                 #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
}


force=0

INPUT_ARGUMENTS=$(getopt -n installer -o p:t:o:d:l:s:ahif --longoptions type:,parameterfile:,storageaccountname:,deployer_tfstate_key:,landscape_tfstate_key:,state_subscription:,ado,auto-approve,force,help -- "$@")
VALID_ARGUMENTS=$?

if [ "$VALID_ARGUMENTS" != "0" ]; then
    showhelp
fi

eval set -- "$INPUT_ARGUMENTS"
while :
do
    case "$1" in
        -t | --type)                               deployment_system="$2"           ; shift 2 ;;
        -p | --parameterfile)                      parameterfile="$2"               ; shift 2 ;;
        -o | --storageaccountname)                 REMOTE_STATE_SA="$2"             ; shift 2 ;;
        -s | --state_subscription)                 STATE_SUBSCRIPTION="$2"          ; shift 2 ;;
        -d | --deployer_tfstate_key)               deployer_tfstate_key="$2"        ; shift 2 ;;
        -l | --landscape_tfstate_key)              landscape_tfstate_key="$2"       ; shift 2 ;;
        -a | --ado)                                ado=1                            ; shift ;;
        -f | --force)                              force=1                          ; shift ;;
        -i | --auto-approve)                       approve="--auto-approve"         ; shift ;;
        -h | --help)                               showhelp
        exit 3                           ; shift ;;
        --) shift; break ;;
    esac
done


tfstate_resource_id=""
tfstate_parameter=""

deployer_tfstate_key_parameter=""
deployer_tfstate_key_exists=false
landscape_tfstate_key_parameter=""
landscape_tfstate_key_exists=false

parameterfile_name=$(basename "${parameterfile}")
param_dirname=$(dirname "${parameterfile}")

echo $STATE_SUBSCRIPTION
echo $deployer_tfstate_key
echo $landscape_tfstate_key


if [ "${param_dirname}" != '.' ]; then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#  $boldred Please run this command from the folder containing the parameter file $resetformatting              #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    exit 3
fi

if [ ! -f "${parameterfile}" ]
then
    printf -v val %-35.35s "$parameterfile"
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                 $boldred  Parameter file does not exist: ${val} $resetformatting #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    exit 2 #No such file or directory
fi

if [ ! -n "${deployment_system}" ]
then
    printf -v val %-40.40s "$deployment_system"
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#  $boldred Incorrect system deployment type specified: ${val}$resetformatting#"
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



if [ $force == 1 ]; then
    rm -Rf .terraform terraform.tfstate*
fi

ext=$(echo ${parameterfile_name} | cut -d. -f2)

# Helper variables
if [ "${ext}" == json ]; then
    environment=$(jq --raw-output .infrastructure.environment "${parameterfile}")
    region=$(jq --raw-output .infrastructure.region "${parameterfile}")
else
    load_config_vars "${param_dirname}"/"${parameterfile}" "environment"
    load_config_vars "${param_dirname}"/"${parameterfile}" "location"
    region=$(echo ${location} | xargs)
fi

if [ ! -n "${environment}" ]
then
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                         $boldred  Incorrect parameter file. $resetformatting                                  #"
    echo "#                                                                                       #"
    echo "#     The file needs to contain the infrastructure.environment attribute!!              #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    exit 65 #data format error
fi

if [ ! -n "${region}" ]
then
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                          $boldred Incorrect parameter file. $resetformatting                                  #"
    echo "#                                                                                       #"
    echo "#       The file needs to contain the infrastructure.region attribute!!                 #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    exit 65 #data format error
fi

key=$(echo "${parameterfile_name}" | cut -d. -f1)

#Persisting the parameters across executions

automation_config_directory=~/.sap_deployment_automation/
generic_config_information="${automation_config_directory}"config
system_config_information="${automation_config_directory}""${environment}""${region}"

deployer_tfstate_key_parameter=''
landscape_tfstate_key_parameter=''

parallelism=10

#Provide a way to limit the number of parallell tasks for Terraform
if [ -n "${TF_PARALLELLISM}" ]; then
    parallelism=TF_PARALLELLISM
   
fi

echo "Parallelism count $parallelism"

#Plugins
if [ ! -d "$HOME/.terraform.d/plugin-cache" ]
then
    mkdir "$HOME/.terraform.d/plugin-cache"
fi
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"

param_dirname=$(pwd)

init "${automation_config_directory}" "${generic_config_information}" "${system_config_information}"

var_file="${param_dirname}"/"${parameterfile}"

extra_vars=""

if [ -f terraform.tfvars ]; then
    extra_vars=" -var-file=${param_dirname}/terraform.tfvars "
fi

if [ "${deployment_system}" == sap_deployer ]
then
    deployer_tfstate_key=${key}.terraform.tfstate
fi

if [ -z "$REMOTE_STATE_SA" ];
then
    load_config_vars "${system_config_information}" "REMOTE_STATE_SA"
else
    save_config_vars "${system_config_information}" REMOTE_STATE_SA
fi

load_config_vars "${system_config_information}" "REMOTE_STATE_RG"
load_config_vars "${system_config_information}" "tfstate_resource_id"

if [ -z "$deployer_tfstate_key" ];
then
  load_config_vars "${system_config_information}" "deployer_tfstate_key"
else
  save_config_vars "${system_config_information}" deployer_tfstate_key
fi

if [ -z "$landscape_tfstate_key" ];
then
  load_config_vars "${system_config_information}" "landscape_tfstate_key"
else
  save_config_vars "${system_config_information}" landscape_tfstate_key
fi

if [ -z "$STATE_SUBSCRIPTION" ];
then
  load_config_vars "${system_config_information}" "STATE_SUBSCRIPTION"
else
  save_config_vars "${system_config_information}" STATE_SUBSCRIPTION
fi

echo "Terraform storage " "${REMOTE_STATE_SA}"

if [ ! -n "${DEPLOYMENT_REPO_PATH}" ]; then
    option="DEPLOYMENT_REPO_PATH"
    missing
    exit 1
fi

# Checking for valid az session
az account show > stdout.az 2>&1
temp=$(grep "az login" stdout.az)
if [ -n "${temp}" ]; then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                          $boldred Please login using az login $resetformatting                                 #"
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
    
fi

account_set=0

cloudIDUsed=$(az account show | grep "cloudShellID")
if [ ! -z "${cloudIDUsed}" ];
then 
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#         $boldred Please login using your credentials or service principal credentials! $resetformatting       #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    exit 67                                                                                             #addressee unknown
fi

#setting the user environment variables
set_executing_user_environment_variables "none"


if [ ! -z "${STATE_SUBSCRIPTION}" ]
then
    $(az account set --sub "${STATE_SUBSCRIPTION}")
    account_set=1
fi

if [ ! -n "${REMOTE_STATE_SA}" ]; then
    read -p "Terraform state storage account name:"  REMOTE_STATE_SA
    
    get_and_store_sa_details ${REMOTE_STATE_SA} "${system_config_information}"
    load_config_vars "${system_config_information}" "STATE_SUBSCRIPTION"
    load_config_vars "${system_config_information}" "REMOTE_STATE_RG"
    load_config_vars "${system_config_information}" "tfstate_resource_id"
    
    if [ ! -z "${STATE_SUBSCRIPTION}" ]
    then
        if [ $account_set==0 ]
        then
            $(az account set --sub "${STATE_SUBSCRIPTION}")
            account_set=1
        fi
    fi
fi


if [ -z "${REMOTE_STATE_SA}" ]; then
    option="REMOTE_STATE_SA"
    missing
    exit 1
fi

if [ -z "${REMOTE_STATE_RG}" ]; then
    get_and_store_sa_details ${REMOTE_STATE_SA} "${system_config_information}"
    load_config_vars "${system_config_information}" "STATE_SUBSCRIPTION"
    load_config_vars "${system_config_information}" "REMOTE_STATE_RG"
    load_config_vars "${system_config_information}" "tfstate_resource_id"
    
    if [ ! -z "${STATE_SUBSCRIPTION}" ]
    then
        if [ $account_set==0 ]
        then
            $(az account set --sub "${STATE_SUBSCRIPTION}")
            account_set=1
        fi
        
    fi
    
fi

if [ "${deployment_system}" != sap_deployer ]
then
    if [ ! -n "${tfstate_resource_id}" ]; then
        get_and_store_sa_details ${REMOTE_STATE_SA} "${system_config_information}"
        load_config_vars "${system_config_information}" "STATE_SUBSCRIPTION"
        load_config_vars "${system_config_information}" "REMOTE_STATE_RG"
        load_config_vars "${system_config_information}" "tfstate_resource_id"
        
    fi
    tfstate_parameter=" -var tfstate_resource_id=${tfstate_resource_id}"
    
    if [ -z "${deployer_tfstate_key}" ]; then
        deployer_tfstate_key_parameter=" "
    else
        deployer_tfstate_key_parameter=" -var deployer_tfstate_key=${deployer_tfstate_key}"
    fi
    
else
    tfstate_parameter=" "
    
    save_config_vars "${system_config_information}" deployer_tfstate_key
fi

if [ "${deployment_system}" == sap_system ]
then
    if [ -n "${landscape_tfstate_key}" ]; then
        landscape_tfstate_key_parameter=" -var landscape_tfstate_key=${landscape_tfstate_key}"
        landscape_tfstate_key_exists=true
    else
        read -p "Workload terraform statefile name :" landscape_tfstate_key
        landscape_tfstate_key_parameter=" -var landscape_tfstate_key=${landscape_tfstate_key}"
        save_config_var "landscape_tfstate_key" "${system_config_information}"
        landscape_tfstate_key_exists=true
    fi
else
    landscape_tfstate_key_parameter=""
fi

terraform_module_directory="${DEPLOYMENT_REPO_PATH}"/deploy/terraform/run/"${deployment_system}"/
export TF_DATA_DIR="${param_dirname}/.terraform"

if [ ! -d "${terraform_module_directory}" ]
then
    printf -v val %-40.40s "$deployment_system"
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#   $boldred Incorrect system deployment type specified: ${val}$resetformatting#"
    echo "#                                                                                       #"
    echo "#     Valid options are:                                                                #"
    echo "#       sap_deployer                                                                    #"
    echo "#       sap_library                                                                     #"
    echo "#       sap_landscape                                                                   #"
    echo "#       sap_system                                                                      #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    exit 1
fi

ok_to_proceed=false
new_deployment=false

check_output=0

if [ $account_set==0 ]
then
    $(az account set --sub "${STATE_SUBSCRIPTION}")
    account_set=1
fi

# This is used to tell Terraform if this is a new deployment or an update
deployment_parameter=""
# This is used to tell Terraform the version information from the state file
version_parameter=""
if [ ! -d ./.terraform/ ];
then
    deployment_parameter=" -var deployment=new "

    terraform -chdir="${terraform_module_directory}" init      \
    --backend-config "subscription_id=${STATE_SUBSCRIPTION}"   \
    --backend-config "resource_group_name=${REMOTE_STATE_RG}"  \
    --backend-config "storage_account_name=${REMOTE_STATE_SA}" \
    --backend-config "container_name=tfstate"                  \
    --backend-config "key=${key}.terraform.tfstate"
    return_value=$?

else
    temp=$(grep "\"type\": \"local\"" .terraform/terraform.tfstate)
    if [ ! -z "${temp}" ]
    then
        terraform -chdir="${terraform_module_directory}" init -upgrade=true -force-copy \
        --backend-config "subscription_id=${STATE_SUBSCRIPTION}"                        \
        --backend-config "resource_group_name=${REMOTE_STATE_RG}"                       \
        --backend-config "storage_account_name=${REMOTE_STATE_SA}"                      \
        --backend-config "container_name=tfstate"                                       \
        --backend-config "key=${key}.terraform.tfstate"
        return_value=$?
        
    else
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#            $cyan The system has already been deployed and the statefile is in Azure $resetformatting       #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""
        if [ ! -n ${approve} ]
        then
            read -p "Do you want to redeploy Y/N?"  ans
            answer=${ans^^}
            if [ $answer == 'Y' ]; then
                ok_to_proceed=true
            else
                exit 1
            fi
        else
            ok_to_proceed=true
        fi
        
        check_output=1
        terraform -chdir="${terraform_module_directory}" init -upgrade=true -reconfigure  \
        --backend-config "subscription_id=${STATE_SUBSCRIPTION}" \
        --backend-config "resource_group_name=${REMOTE_STATE_RG}" \
        --backend-config "storage_account_name=${REMOTE_STATE_SA}" \
        --backend-config "container_name=tfstate" \
        --backend-config "key=${key}.terraform.tfstate"
        return_value=$?
        
    fi
fi

if [ 0 != $return_value ]
then
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                            $boldreduscore!!! Error when Initializing !!!$resetformatting                            #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    exit $return_value        
fi

if [ 1 == $check_output ]
then
    terraform -chdir=$terraform_module_directory refresh -var-file=${var_file} ${tfstate_parameter} ${landscape_tfstate_key_parameter} ${deployer_tfstate_key_parameter} ${extra_vars}
    
    outputs=$(terraform -chdir="${terraform_module_directory}" output )
    if echo "${outputs}" | grep "No outputs"; then
        ok_to_proceed=true
        new_deployment=true
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#                                 $cyan  New deployment $resetformatting                                      #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        
        deployment_parameter=" -var deployment=new "
        
    else
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#                          $cyan Existing deployment was detected$resetformatting                            #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""
        
        deployment_parameter=" "
        
        deployed_using_version=$(terraform -chdir="${terraform_module_directory}" output automation_version | tr -d \")
        
        if [ ! -n "${deployed_using_version}" ]; then
            echo ""
            echo "#########################################################################################"
            echo "#                                                                                       #"
            echo -e "#   $boldred The environment was deployed using an older version of the Terrafrom templates$resetformatting     #"
            echo "#                                                                                       #"
            echo "#                               !!! Risk for Data loss !!!                              #"
            echo "#                                                                                       #"
            echo "#        Please inspect the output of Terraform plan carefully before proceeding        #"
            echo "#                                                                                       #"
            echo "#########################################################################################"

            if [ 1 == $ado ] ; then
              unset TF_DATA_DIR
              exit 1
            fi
            
            read -p "Do you want to continue Y/N?"  ans
            answer=${ans^^}
            if [ $answer == 'Y' ]; then
                ok_to_proceed=true
            else
                unset TF_DATA_DIR
                exit 1
            fi
        else
            version_parameter=" -var terraform_template_version=${deployed_using_version} "
            
            printf -v val %-.20s "$deployed_using_version"            
            echo ""
            echo "#########################################################################################"
            echo "#                                                                                       #"
            echo -e "#              $cyan Deployed using the Terraform templates version: $val $resetformatting                #"
            echo "#                                                                                       #"
            echo "#########################################################################################"
            echo ""
            #Add version logic here
        fi
    fi
fi

echo ""
echo "#########################################################################################"
echo "#                                                                                       #"
echo -e "#                            $cyan Running Terraform plan $resetformatting                                   #"
echo "#                                                                                       #"
echo "#########################################################################################"
echo ""

if [ -f plan_output.log ]
then
    rm plan_output.log
fi

allParams=$(printf " -var-file=%s %s %s %s %s %s %s" "${var_file}" "${extra_vars}" "${tfstate_parameter}" "${landscape_tfstate_key_parameter}" "${deployer_tfstate_key_parameter}" "${deployment_parameter}" "${version_parameter}" )
echo $allParams

terraform -chdir="$terraform_module_directory" plan -no-color -detailed-exitcode $allParams > plan_output.log
return_value=$?
if [ 1 == $return_value ]
then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                             $boldreduscoreErrors during the plan phase$resetformatting                              #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    if [ -f plan_output.log ]
    then
        cat plan_output.log
        rm plan_output.log
    fi
    unset TF_DATA_DIR
    exit $return_value
fi

if [ 0 == $return_value ] ; then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                          $cyan Infrastructure is up to date $resetformatting                               #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    if [ -f plan_output.log ]
    then
        rm plan_output.log
    fi
    
    if [ "${deployment_system}" == sap_landscape ]
    then
        if [ $landscape_tfstate_key_exists == false ]
        then
            save_config_vars "${system_config_information}" \
            landscape_tfstate_key
        fi
    fi

    if [ "${deployment_system}" == sap_library ]
    then
        
        tfstate_resource_id=$(terraform -chdir="${terraform_module_directory}" output tfstate_resource_id| tr -d \")
        STATE_SUBSCRIPTION=$(echo $tfstate_resource_id | cut -d/ -f3 | tr -d \" | xargs)

        az account set --sub $STATE_SUBSCRIPTION

        REMOTE_STATE_SA=$(terraform -chdir="${terraform_module_directory}" output remote_state_storage_account_name| tr -d \")
        
        get_and_store_sa_details ${REMOTE_STATE_SA} "${system_config_information}"
        
    fi

    unset TF_DATA_DIR
    exit $return_value
fi
if [ 2 == $return_value ] ; then
    if ! grep "0 to change, 0 to destroy" plan_output.log ; then
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#                               $boldreduscore!!! Risk for Data loss !!!$resetformatting                              #"
        echo "#                                                                                       #"
        echo "#        Please inspect the output of Terraform plan carefully before proceeding        #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""
        if [ 1 == "$ado" ]; then
            unset TF_DATA_DIR
            exit 1
        fi
        read -n 1 -r -s -p $'Press enter to continue...\n'
        
        cat plan_output.log
        read -p "Do you want to continue with the deployment Y/N?"  ans
        answer=${ans^^}
        if [ $answer == 'Y' ]; then
            ok_to_proceed=true
        else
            unset TF_DATA_DIR
            exit 1
        fi
    else
        ok_to_proceed=true
    fi
fi

if [ $ok_to_proceed ]; then
    
    if [ -f error.log ]
    then
        rm error.log
    fi
    if [ -f plan_output.log ]
    then
        rm plan_output.log
    fi
    
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                            $cyan Running Terraform apply$resetformatting                                   #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    
    allParams=$(printf " -var-file=%s %s %s %s %s %s %s" "${var_file}" "${extra_vars}" "${tfstate_parameter}" "${landscape_tfstate_key_parameter}" "${deployer_tfstate_key_parameter}" "${deployment_parameter}" "${version_parameter}" )
    
    terraform -chdir="${terraform_module_directory}" apply -parallelism=$parallelism ${approve} $allParams  2>error.log
    return_value=$?
    
    if [ 0 != $return_value ] ; then
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#                          $boldreduscore!Errors during the apply phase!$resetformatting                              #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""
        cat error.log
        rm error.log
        unset TF_DATA_DIR
        exit $return_value
    fi
    
fi

if [ "${deployment_system}" == sap_landscape ]
then
    save_config_vars "${system_config_information}" \
    landscape_tfstate_key
fi

if [ "${deployment_system}" == sap_library ]
then
    
    tfstate_resource_id=$(terraform -chdir="${terraform_module_directory}" output tfstate_resource_id| tr -d \")
    STATE_SUBSCRIPTION=$(echo $tfstate_resource_id | cut -d/ -f3 | tr -d \" | xargs)

    az account set --sub $STATE_SUBSCRIPTION

    REMOTE_STATE_SA=$(terraform -chdir="${terraform_module_directory}" output remote_state_storage_account_name| tr -d \")
    
    get_and_store_sa_details ${REMOTE_STATE_SA} "${system_config_information}"
    
fi

unset TF_DATA_DIR
exit $return_value
