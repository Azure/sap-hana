#!/bin/bash
. "$(dirname "${BASH_SOURCE[0]}")/deploy_utils.sh"

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
    echo "#   Usage: install_workloadzone.sh                                                      #"
    echo "#    -p parameter file                                                                  #"
    echo "#    -f will remove .terraform and local state files before deployment                  #"
    echo "#    -d Deployer terraform state file name                                              #"
    echo "#    -e Deployer environment, typically MGMT                                            #"
    echo "#    -i interactive true/false setting the value to false will not prompt before apply  #"
    echo "#    -h Show help                                                                       #"
    echo "#                                                                                       #"
    echo "#   Example:                                                                            #"
    echo "#                                                                                       #"
    echo "#   [REPO-ROOT]deploy/scripts/install_workloadzone.sh \                                 #"
    echo "#      -p PROD-WEEU-SAP01-INFRASTRUCTURE.json \                                         #"
    echo "#      -i true                                                                          #"
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

show_help=false
force=0

while getopts ":p:t:d:h:f:e:i:s:c:p" option; do
    case "${option}" in
        p) parameterfile=${OPTARG};;
        i) approve="--auto-approve";;
        f) force=1 ;;
        d) deployer_tfstate_key=${OPTARG};;
        e) deployer_environment=${OPTARG};;
        s) subscription=${OPTARG};;
        c) client_id=${OPTARG};;
        p) spn_secret=${OPTARG};;
        t) tenant_id=${OPTARG};;

        h) showhelp
            exit 3
        ;;
    esac
done
tfstate_resource_id=""
tfstate_parameter=""

deployer_tfstate_key_parameter=""
deployer_tfstate_key_exists=false
landscape_tfstate_key=""
landscape_tfstate_key_parameter=""
landscape_tfstate_key_exists=false

deployment_system=sap_landscape

workload_dirname=$(dirname "${parameterfile}")
workload_file_parametername=$(basename "${parameterfile}")

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

if [ ! -f "${workload_file_parametername}" ]
then
    printf -v val %-40.40s "$workload_file_parametername"
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#               Parameter file does not exist: ${val} #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    exit
fi


# Read environment
environment=$(cat "${parameterfile}" | jq .infrastructure.environment | tr -d \")
region=$(cat "${parameterfile}" | jq .infrastructure.region | tr -d \")
key=$(echo "${workload_file_parametername}" | cut -d. -f1)

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
workload_config_information="${automation_config_directory}""${environment}""${region}"

if [ "${force}" == 1 ]
then
    if [ -f $workload_config_information ]
    then
        rm $workload_config_information
    fi
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


init "${automation_config_directory}" "${generic_config_information}" "${workload_config_information}"

param_dirname=$(pwd)
export TF_DATA_DIR="${param_dirname}/.terraform"
var_file="${param_dirname}"/"${parameterfile}"

if [ ! -z "$subscription" ]
then
    save_config_var "subscription" "${workload_config_information}"
fi

if [ ! -z "$client_id" ]
then
    save_config_var "client_id" "${workload_config_information}"
fi

if [ ! -z "$tenant_id" ]
then
    save_config_var "tenant_id" "${workload_config_information}"
fi



load_config_vars "${workload_config_information}" "REMOTE_STATE_SA"
load_config_vars "${workload_config_information}" "REMOTE_STATE_RG"
load_config_vars "${workload_config_information}" "tfstate_resource_id"
load_config_vars "${workload_config_information}" "STATE_SUBSCRIPTION"
load_config_vars "${workload_config_information}" "ARM_SUBSCRIPTION_ID"

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

if [ -z "${REMOTE_STATE_SA}" ]
then
    # Ask for deployer environment name and try to read the deployer state file and resource group details from the configuration file
    
    if [ -z $deployer_environment ]
    then
        read -p "Deployer environment name: " deployer_environment
    fi

    echo "REMOTE_STATE_SA" $REMOTE_STATE_SA
    
    deployer_config_information="${automation_config_directory}""${deployer_environment}""${region}"
    load_config_vars "${deployer_config_information}" "keyvault"
    load_config_vars "${deployer_config_information}" "REMOTE_STATE_RG"
    load_config_vars "${deployer_config_information}" "REMOTE_STATE_SA"
    load_config_vars "${deployer_config_information}" "tfstate_resource_id"
    load_config_vars "${deployer_config_information}" "deployer_tfstate_key"
    STATE_SUBSCRIPTION=$(echo $tfstate_resource_id | cut -d/ -f3 | tr -d \" | xargs)
    
    if [ ! -z "${STATE_SUBSCRIPTION}" ]
    then
        if [ ${account_set} == 0 ]
        then
            $(az account set --sub "${STATE_SUBSCRIPTION}")
            account_set=1
        fi
        
        save_config_vars "${workload_config_information}" \
        REMOTE_STATE_RG \
        REMOTE_STATE_SA \
        tfstate_resource_id \
        STATE_SUBSCRIPTION \
        keyvault \
        deployer_tfstate_key

    fi
fi

if [ ! -z $keyvault ]
then
    secretname="${environment}"-client-id
    echo $keyvault
    echo $secretname
    az keyvault secret show --name $secretname --vault $keyvault 2>error.log > kv.log
    if [ -f error.log ]
    then
        temp=$(grep "ERROR:" error.log)
        
        if [ -n "${temp}" ];
        then
            if [ ! -z "$spn_secret" ]
            then
                secret_param=$(printf " -s %s " "${spn_secret}")
                allParams="${env_param}""${keyvault_param}""${region_param}""${secret_param}"
                
                "${DEPLOYMENT_REPO_PATH}"deploy/scripts/set_secrets.sh $allParams -w
                if [ $? -eq 255 ]
                then
                    exit $?
                fi
            else
                read -p "Do you want to specify the Workload SPN Details Y/N?"  ans
                answer=${ans^^}
                if [ $answer == 'Y' ]; then
                    load_config_vars ${workload_config_information} "keyvault"
                    if [ ! -z $keyvault ]
                    then
                        # Key vault was specified in ~/.sap_deployment_automation in the deployer file
                        keyvault_param=$(printf " -v %s " "${keyvault}")
                    fi
                    
                    env_param=$(printf " -e %s " "${environment}")
                    region_param=$(printf " -r %s " "${region}")
                    
                    allParams="${env_param}""${keyvault_param}""${region_param}"
                    
                    "${DEPLOYMENT_REPO_PATH}"deploy/scripts/set_secrets.sh $allParams -w
                    if [ $? -eq 255 ]
                    then
                        exit $?
                    fi
                fi
            fi
        fi
    fi
    if [ -f error.log ]
    then
        rm error.log
    fi
    
    if [ -f kv.log ]
    then
        rm kv.log
    fi
    
fi

if [ -z "${deployer_tfstate_key}" ]
then
    load_config_vars "${workload_config_information}" "deployer_tfstate_key"
    if [ ! -z "${deployer_tfstate_key}" ]
    then
        # Deployer state was specified in ~/.sap_deployment_automation library config
        deployer_tfstate_key_parameter=" -var deployer_tfstate_key=${deployer_tfstate_key}"
        deployer_tfstate_key_exists=true
    else
        load_config_vars "${deployer_config_information}" "deployer_tfstate_key"
        if [ ! -z "${deployer_tfstate_key}" ]
        then
            # Deployer state was specified in ~/.sap_deployment_automation library config
            deployer_tfstate_key_parameter=" -var deployer_tfstate_key=${deployer_tfstate_key}"
            save_config_vars "${workload_config_information}" deployer_tfstate_key
            deployer_tfstate_key_exists=true
        else
            read -p "Deployer state file name (empty for no deployer): "  deployer_tfstate_key
            deployer_tfstate_key_parameter=" -var deployer_tfstate_key=${deployer_tfstate_key}"
            save_config_vars "${workload_config_information}" deployer_tfstate_key
        fi
        
    fi
else
    deployer_tfstate_key_parameter=" -var deployer_tfstate_key=${deployer_tfstate_key}"
    save_config_vars "${workload_config_information}" deployer_tfstate_key
    
fi

if [ ! -n "${DEPLOYMENT_REPO_PATH}" ]; then
    option="DEPLOYMENT_REPO_PATH"
    missing
    exit -1
fi

if [ ! -n "${ARM_SUBSCRIPTION_ID}" ]; then
    read -p "Please provide the subscription id for the workload:" ARM_SUBSCRIPTION_ID
    save_config_vars "${workload_config_information}" ARM_SUBSCRIPTION_ID
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
        
        save_config_vars "${workload_config_information}" REMOTE_STATE_RG \
        REMOTE_STATE_SA \
        tfstate_resource_id \
        STATE_SUBSCRIPTION
    fi
    
    tfstate_parameter=" -var tfstate_resource_id=${tfstate_resource_id}"
    
fi

if [ ! -n "${REMOTE_STATE_RG}" ]; then
    if [  -n "${REMOTE_STATE_SA}" ]; then
        REMOTE_STATE_RG=$(az resource list --name ${REMOTE_STATE_SA} | jq .[0].resourceGroup  | tr -d \" | xargs)
        tfstate_resource_id=$(az resource list --name ${REMOTE_STATE_SA} | jq .[0].id  | tr -d \" | xargs)
        STATE_SUBSCRIPTION=$(echo $tfstate_resource_id | cut -d/ -f3 | tr -d \" | xargs)
        
        save_config_vars "${workload_config_information}" \
        REMOTE_STATE_RG \
        REMOTE_STATE_SA \
        tfstate_resource_id \
        STATE_SUBSCRIPTION
        
        tfstate_parameter=" -var tfstate_resource_id=${tfstate_resource_id}"
    else
        
        option="REMOTE_STATE_RG"
        read -p "Remote state resource group name:"  REMOTE_STATE_RG
        save_config_vars "${workload_config_information}" REMOTE_STATE_RG
    fi
fi

if [ ! -z "${tfstate_resource_id}" ]
then
    tfstate_parameter=" -var tfstate_resource_id=${tfstate_resource_id}"
fi

terraform_module_directory="${DEPLOYMENT_REPO_PATH}"deploy/terraform/run/"${deployment_system}"/

if [ ! -d "${terraform_module_directory}" ]
then
    printf -v val %-40.40s "$deployment_system"
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#   Incorrect system deployment type specified: ${val}#"
    echo "#                                                                                       #"
    echo "#     Valid options are:                                                                #"
    echo "#       sap_landscape                                                                   #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    exit -1
fi

ok_to_proceed=false
new_deployment=false

#Plugins
if [ ! -d "$HOME/.terraform.d/plugin-cache" ]
then
    mkdir "$HOME/.terraform.d/plugin-cache"
fi
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"
root_dirname=$(pwd)

check_output=0

if [ $account_set==0 ]
then
    $(az account set --sub "${STATE_SUBSCRIPTION}")
    account_set=1
fi

if [ ! -d ./.terraform/ ];
then
    terraform -chdir="${terraform_module_directory}" init -upgrade=true  --backend-config "subscription_id=${STATE_SUBSCRIPTION}" \
    --backend-config "resource_group_name=${REMOTE_STATE_RG}" \
    --backend-config "storage_account_name=${REMOTE_STATE_SA}" \
    --backend-config "container_name=tfstate" \
    --backend-config "key=${key}.terraform.tfstate"
else
    temp=$(grep "\"type\": \"local\"" .terraform/terraform.tfstate)
    if [ ! -z "${temp}" ]
    then
        
        terraform -chdir="${terraform_module_directory}" init -upgrade=true -force-copy --backend-config "subscription_id=${STATE_SUBSCRIPTION}" \
        --backend-config "resource_group_name=${REMOTE_STATE_RG}" \
        --backend-config "storage_account_name=${REMOTE_STATE_SA}" \
        --backend-config "container_name=tfstate" \
        --backend-config "key=${key}.terraform.tfstate"
    else
        terraform -chdir="${terraform_module_directory}" init -upgrade=true -reconfigure --backend-config "subscription_id=${STATE_SUBSCRIPTION}" \
        --backend-config "resource_group_name=${REMOTE_STATE_RG}" \
        --backend-config "storage_account_name=${REMOTE_STATE_SA}" \
        --backend-config "container_name=tfstate" \
        --backend-config "key=${key}.terraform.tfstate"
        check_output=1
    fi
    
fi

if [ 1 == $check_output ]
then
    outputs=$(terraform -chdir="${terraform_module_directory}" output)
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

terraform -chdir="${terraform_module_directory}" plan -var-file=${var_file} $tfstate_parameter $deployer_tfstate_key_parameter > plan_output.log

if [ ! $new_deployment ]
then
    if [ grep "No changes" plan_output.log ]
    then
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo "#                           Infrastructure is up to date                                #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""
        rm plan_output.log
        unset TF_DATA_DIR
    
        exit 0
    fi
    if [ grep "0 to change, 0 to destroy" plan_output.log ]
    then
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo "#                               !!! Risk for Data loss !!!                              #"
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
    
    rm plan_output.log
    
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#                             Running Terraform apply                                   #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    
    terraform -chdir="${terraform_module_directory}" apply ${approve} -var-file=${var_file} $tfstate_parameter $landscape_tfstate_key_parameter $deployer_tfstate_key_parameter
fi

return_value=0
landscape_tfstate_key=${key}.terraform.tfstate
save_config_var "landscape_tfstate_key" "${workload_config_information}"

unset TF_DATA_DIR

exit $return_value