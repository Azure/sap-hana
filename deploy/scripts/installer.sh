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
    echo "#    -p parameter file                                                                  #"
    echo "#    -t type of system to deploy                                                        #"
    echo "#       valid options:                                                                  #"
    echo "#         sap_deployer                                                                  #"
    echo "#         sap_library                                                                   #"
    echo "#         sap_landscape                                                                 #"
    echo "#         sap_system                                                                    #"
    echo "#    -h Show help                                                                       #"
    echo "#                                                                                       #"
    echo "#   Example:                                                                            #"
    echo "#                                                                                       #"
    echo "#   [REPO-ROOT]deploy/scripts/installer.sh \                                            #"
    echo "#      -p PROD-WEEU-DEP00-INFRASTRUCTURE.json \                                         #"
    echo "#      -t sap_deployer                                                                  #"
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

while getopts "p:t:ihf" option; do
    case "${option}" in
        p) parameterfile=${OPTARG};;
        t) deployment_system=${OPTARG};;
        i) approve="--auto-approve";;
        f) force=1
        ;;
        h) showhelp
            exit 3
        ;;
        ?) echo "Invalid option: -${OPTARG}."
            exit 2
        ;;
    esac
done

tfstate_resource_id=""
tfstate_parameter=""

deployer_tfstate_key=""
deployer_tfstate_key_parameter=""
deployer_tfstate_key_exists=false
landscape_tfstate_key=""
landscape_tfstate_key_parameter=""
landscape_tfstate_key_exists=false

parameterfile_name=$(basename "${parameterfile}")
param_dirname=$(dirname "${parameterfile}")

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
    exit
fi

if [ ! -n "${deployment_system}" ]
then
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
    exit -1
fi



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


# Read environment
environment=$(cat "${parameterfile}" | jq .infrastructure.environment | tr -d \")
region=$(cat "${parameterfile}" | jq .infrastructure.region | tr -d \")

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

key=$(echo "${parameterfile_name}" | cut -d. -f1)

#Persisting the parameters across executions

automation_config_directory=~/.sap_deployment_automation/
generic_config_information="${automation_config_directory}"config
system_config_information="${automation_config_directory}""${environment}""${region}"


#Plugins
if [ ! -d "$HOME/.terraform.d/plugin-cache" ]
then
    mkdir "$HOME/.terraform.d/plugin-cache"
fi
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"

param_dirname=$(pwd)
root_dirname=$(pwd)

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

load_config_vars "${system_config_information}" "REMOTE_STATE_SA"
load_config_vars "${system_config_information}" "REMOTE_STATE_RG"
load_config_vars "${system_config_information}" "tfstate_resource_id"
load_config_vars "${system_config_information}" "deployer_tfstate_key"
load_config_vars "${system_config_information}" "landscape_tfstate_key"
load_config_vars "${system_config_information}" "STATE_SUBSCRIPTION"

echo "Terraform storage " $REMOTE_STATE_SA

deployer_tfstate_key_parameter=''
if [ "${deployment_system}" != sap_deployer ]
then
    if [ ! -n "$=${deployer_tfstate_key}" ]; then
        deployer_tfstate_key_parameter=" "
    else
        deployer_tfstate_key_parameter=" -var deployer_tfstate_key=${deployer_tfstate_key}"
        deployer_tfstate_key_exists=true
    fi
else
    STATE_SUBSCRIPTION=$ARM_SUBSCRIPTION_ID
    
fi

landscape_tfstate_key_parameter=''
if [ "${deployment_system}" == sap_system ]
then
    if [ -n "$=${landscape_tfstate_key}" ]; then
        landscape_tfstate_key_parameter=" -var landscape_tfstate_key=${landscape_tfstate_key}"
        landscape_tfstate_key_exists=true
    else
        read -p "Workload terraform statefile name :" landscape_tfstate_key
        landscape_tfstate_key_parameter=" -var landscape_tfstate_key=${landscape_tfstate_key}"
        save_config_var "landscape_tfstate_key" "${system_config_information}"
        landscape_tfstate_key_exists=true
    fi
fi

if [ ! -n "${DEPLOYMENT_REPO_PATH}" ]; then
    option="DEPLOYMENT_REPO_PATH"
    missing
    exit -1
fi


# Checking for valid az session
az account show > stdout.az 2>&1
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

account_set=0

if [ ! -z "${STATE_SUBSCRIPTION}" ]
then
    $(az account set --sub "${STATE_SUBSCRIPTION}")
    account_set=1
fi

if [ ! -n "${REMOTE_STATE_SA}" ]; then
    read -p "Terraform state storage account name:"  REMOTE_STATE_SA
    REMOTE_STATE_RG=$(az resource list --name ${REMOTE_STATE_SA} | jq .[0].resourceGroup  | tr -d \" | xargs)
    tfstate_resource_id=$(az resource list --name ${REMOTE_STATE_SA} | jq .[0].id  | tr -d \" | xargs)
    STATE_SUBSCRIPTION=$(echo $tfstate_resource_id | cut -d/ -f3 | tr -d \" | xargs)
    if [ ! -z "${STATE_SUBSCRIPTION}" ]
    then
        if [ $account_set==0 ] 
        then
            $(az account set --sub "${STATE_SUBSCRIPTION}")
            account_set=1
        fi
        
        save_config_vars "${workload_config_information}" \
        REMOTE_STATE_RG \
        REMOTE_STATE_SA \
        tfstate_resource_id \
        STATE_SUBSCRIPTION
    fi

    tfstate_parameter=" -var tfstate_resource_id=${tfstate_resource_id}"
    
    if [ "${deployment_system}" != sap_deployer ]
    then
        tfstate_parameter=" -var tfstate_resource_id=${tfstate_resource_id}"
    fi
    
fi


if [ ! -n "${REMOTE_STATE_SA}" ]; then
    option="REMOTE_STATE_SA"
    missing
    exit -1
fi

if [ ! -n "${REMOTE_STATE_RG}" ]; then
    REMOTE_STATE_RG=$(az resource list --name ${REMOTE_STATE_SA} | jq .[0].resourceGroup  | tr -d \" | xargs)
    tfstate_resource_id=$(az resource list --name ${REMOTE_STATE_SA} | jq .[0].id  | tr -d \" | xargs)
    STATE_SUBSCRIPTION=$(echo $tfstate_resource_id | cut -d/ -f3 | tr -d \" | xargs)
    
    if [ ! -z "${STATE_SUBSCRIPTION}" ]
    then
        if [ $account_set==0 ] 
        then
            $(az account set --sub "${STATE_SUBSCRIPTION}")
            account_set=1
        fi
        
        save_config_vars "${workload_config_information}" \
        REMOTE_STATE_RG \
        tfstate_resource_id \
        STATE_SUBSCRIPTION
    fi
    
    tfstate_parameter=" -var tfstate_resource_id=${tfstate_resource_id}"
    
    if [ "${deployment_system}" != sap_deployer ]
    then
        tfstate_parameter=" -var tfstate_resource_id=${tfstate_resource_id}"
    fi
fi

if [ "${deployment_system}" != sap_deployer ]
then
    if [ ! -n "${tfstate_resource_id}" ]; then
        tfstate_resource_id=$(az resource list --name ${REMOTE_STATE_SA} | jq .[0].id  | tr -d \" | xargs)
        STATE_SUBSCRIPTION=$(echo $tfstate_resource_id | cut -d/ -f3 | tr -d \" | xargs)
        
        save_config_vars "${system_config_information}" \
        tfstate_resource_id \
        STATE_SUBSCRIPTION
        
        tfstate_parameter=" -var tfstate_resource_id=${tfstate_resource_id}"
        
    fi
else
    save_config_vars "${system_config_information}" \
    deployer_tfstate_key
fi

if [ "${deployment_system}" != sap_system ]
then
    landscape_tfstate_key_parameter=""
fi

if [ ! -z "${tfstate_resource_id}" ]
then
    if [ "${deployment_system}" != sap_deployer ]
    then
        tfstate_parameter=" -var tfstate_resource_id=${tfstate_resource_id}"
    fi
fi


terraform_module_directory="${DEPLOYMENT_REPO_PATH}"deploy/terraform/run/"${deployment_system}"/
export TF_DATA_DIR="${param_dirname}/.terraform"

if [ ! -d "${terraform_module_directory}" ]
then
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
    exit -1
fi

ok_to_proceed=false
new_deployment=false

check_output=0

if [ $account_set==0 ] 
then
    $(az account set --sub "${STATE_SUBSCRIPTION}")
    account_set=1
fi

if [ ! -d ./.terraform/ ];
then
    terraform -chdir="${terraform_module_directory}" init -upgrade=true -force-copy \
    --backend-config "subscription_id=${STATE_SUBSCRIPTION}" \
    --backend-config "resource_group_name=${REMOTE_STATE_RG}" \
    --backend-config "storage_account_name=${REMOTE_STATE_SA}" \
    --backend-config "container_name=tfstate" \
    --backend-config "key=${key}.terraform.tfstate"
else
    temp=$(grep "\"type\": \"local\"" .terraform/terraform.tfstate)
    if [ ! -z "${temp}" ]
    then
        terraform -chdir="${terraform_module_directory}" init -upgrade=true -force-copy \
        --backend-config "subscription_id=${STATE_SUBSCRIPTION}" \
        --backend-config "resource_group_name=${REMOTE_STATE_RG}" \
        --backend-config "storage_account_name=${REMOTE_STATE_SA}" \
        --backend-config "container_name=tfstate" \
        --backend-config "key=${key}.terraform.tfstate"

    else
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo "#             The system has already been deployed and the statefile is in Azure        #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""
        if [ ! -n "${approve}" ] 
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

        terraform -chdir="${terraform_module_directory}" init -upgrade=true -reconfigure  \
        --backend-config "subscription_id=${STATE_SUBSCRIPTION}" \
        --backend-config "resource_group_name=${REMOTE_STATE_RG}" \
        --backend-config "storage_account_name=${REMOTE_STATE_SA}" \
        --backend-config "container_name=tfstate" \
        --backend-config "key=${key}.terraform.tfstate"
        check_output=1
        
    fi
fi

if [ 1 == $check_output ]
then
    terraform -chdir=$terraform_module_directory refresh -no-color -var-file=${var_file} ${tfstate_parameter} ${landscape_tfstate_key_parameter} ${deployer_tfstate_key_parameter} ${extra_vars}

    outputs=$(terraform -chdir="${terraform_module_directory}" output )
    if echo "${outputs}" | grep "No outputs"; then
        ok_to_proceed=true
        new_deployment=true
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo "#                                   New deployment                                      #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
    else
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo "#                           Existing deployment was detected                            #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""


        deployed_using_version=$(terraform -chdir="${terraform_module_directory}" output automation_version)

        if [ ! -n "${deployed_using_version}" ]; then
            echo ""
            echo "#########################################################################################"
            echo "#                                                                                       #"
            echo "#    The environment was deployed using an older version of the Terrafrom templates     #"
            echo "#                                                                                       #"
            echo "#                               !!! Risk for Data loss !!!                              #"
            echo "#                                                                                       #"
            echo "#        Please inspect the output of Terraform plan carefully before proceeding        #"
            echo "#                                                                                       #"
            echo "#########################################################################################"
            
            read -p "Do you want to continue Y/N?"  ans
            answer=${ans^^}
            if [ $answer == 'Y' ]; then
                ok_to_proceed=true
            else
                unset TF_DATA_DIR
                exit 1
            fi
        else
            
            echo ""
            echo "#########################################################################################"
            echo "#                                                                                       #"
            echo "# Terraform templates version:" $deployed_using_version "were used in the deployment "
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
echo "#                             Running Terraform plan                                    #"
echo "#                                                                                       #"
echo "#########################################################################################"
echo ""

if [ -f plan_output.log ]
then
    rm plan_output.log
fi


echo "${tfstate_parameter}"
echo "${landscape_tfstate_key_parameter}"
echo "${deployer_tfstate_key_parameter}"
echo "${extra_vars}"

allParams=$(printf " -var-file=%s %s %s %s %s" "${var_file}" "${extra_vars}" "${tfstate_parameter}" "${landscape_tfstate_key_parameter}" "${deployer_tfstate_key_parameter}")
echo $allParams

terraform -chdir="$terraform_module_directory" plan -no-color $allParams  
str1=$(grep "Error: " error.log)
if [ -n "${str1}" ]
then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                            $boldreduscore Errors during the plan phase $resetformatting                             #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    cat error.log
    rm error.log
    if [ -f plan_output.log ]
    then
        rm plan_output.log
    fi
    unset TF_DATA_DIR
    exit -1
fi

if [ ! $new_deployment ]
then
    str1=$(grep "0 to add, 0 to change, 0 to destroy" plan_output.log)
    str2=$(grep "No changes" plan_output.log)
    if [ -n "${str1}" ] || [ -n "${str2}" ]; then
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo "#                           Infrastructure is up to date                                #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""
        rm plan_output.log
        
        if [ "${deployment_system}" == sap_landscape ]
        then
            if [ $landscape_tfstate_key_exists == false ]
            then
                save_config_vars "${system_config_information}" \
                landscape_tfstate_key
            fi
        fi
        unset TF_DATA_DIR
        exit 0
    fi
    if ! grep "0 to change, 0 to destroy" plan_output.log ; then
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#                              $boldreduscore !!! Risk for Data loss !!!  $resetformatting                             #"
        echo "#                                                                                       #"
        echo "#        Please inspect the output of Terraform plan carefully before proceeding        #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""
        read -n 1 -r -s -p $'Press enter to continue...\n'
        
        cat plan_output.log
        read -p "Do you want to continue with the deployment Y/N?"  ans
        answer=${ans^^}
        if [ $answer == 'Y' ]; then
            ok_to_proceed=true
        else
            unset TF_DATA_DIR
            exit -1
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
    echo "#                             Running Terraform apply                                   #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""

    allParams=$(printf " -var-file=%s %s %s %s %s" "${var_file}" "${extra_vars}" "${tfstate_parameter}" "${landscape_tfstate_key_parameter}" "${deployer_tfstate_key_parameter}")

    
    terraform -chdir="${terraform_module_directory}" apply ${approve} $allParams  2>error.log
 
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
        
fi

if [ "${deployment_system}" == sap_landscape ]
then
    save_config_vars "${system_config_information}" \
    landscape_tfstate_key
fi

if [ "${deployment_system}" == sap_library ]
then

    REMOTE_STATE_SA=$(terraform -chdir="${terraform_module_directory}" output remote_state_storage_account_name| tr -d \")
    REMOTE_STATE_RG=$(az resource list --name ${REMOTE_STATE_SA} | jq .[0].resourceGroup  | tr -d \" | xargs)
    tfstate_resource_id=$(az resource list --name ${REMOTE_STATE_SA} | jq .[0].id  | tr -d \" | xargs)
    STATE_SUBSCRIPTION=$(echo $tfstate_resource_id | cut -d/ -f3 | tr -d \" | xargs)
    
    save_config_vars "${system_config_information}" \
    REMOTE_STATE_RG \
    REMOTE_STATE_SA \
    tfstate_resource_id \
    STATE_SUBSCRIPTION
    
fi

unset TF_DATA_DIR
exit 0
