#!/bin/bash
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

while getopts ":p:t:i:d:h" option; do
    case "${option}" in
        p) parameterfile=${OPTARG};;
        i) approve="--auto-approve";;
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

deployment_system=sap_landscape

workload_dirname=$(dirname "${parameterfile}")
workload_file_parametername=$(basename "${parameterfile}")


# Read environment
environment=$(grep "environment" "${parameterfile}" -m1  | cut -d: -f2 | cut -d, -f1 | tr -d \")
region=$(grep "region" "${parameterfile}" -m1  | cut -d: -f2 | cut -d, -f1 | tr -d \")
key=$(echo "${workload_file_parametername}" | cut -d. -f1)

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

#Persisting the parameters across executions

automation_config_directory=~/.sap_deployment_automation/
generic_config_information="${automation_config_directory}"config
library_config_information="${automation_config_directory}""${region}"
workload_config_information="${automation_config_directory}""${region}""${environment}"

if [ ! -d ${automation_config_directory} ]
then
    # No configuration directory exists
    mkdir $automation_config_directory
    if [ -n "${DEPLOYMENT_REPO_PATH}" ]; then
        # Store repo path in ~/.sap_deployment_automation/config
        echo "DEPLOYMENT_REPO_PATH=${DEPLOYMENT_REPO_PATH}" >> "${generic_config_information}"
        config_stored=1
    fi
    if [ -n "$ARM_SUBSCRIPTION_ID" ]; then
        # Store ARM Subscription info in ~/.sap_deployment_automation
        echo "ARM_SUBSCRIPTION_ID=${ARM_SUBSCRIPTION_ID}" >> "${library_config_information}"
        arm_config_stored=1
    fi
else
    temp=$(grep "DEPLOYMENT_REPO_PATH" "${generic_config_information}")
    if [ ! -z "${temp}" ]
    then
        # Repo path was specified in ~/.sap_deployment_automation/config
        DEPLOYMENT_REPO_PATH=$(echo "${temp}" | cut -d= -f2)

        config_stored=1
    else
        config_stored=0
    fi

    temp=$(grep "REMOTE_STATE_RG" "${library_config_information}")
    if [ ! -z "${temp}" ]
    then
        # Remote state storage group was specified in ~/.sap_deployment_automation library config
        REMOTE_STATE_RG=$(echo "${temp}" | cut -d= -f2)
    fi

    temp=$(grep "REMOTE_STATE_SA" "${library_config_information}")
    if [ ! -z "${temp}" ]
    then
        # Remmote state storage group was specified in ~/.sap_deployment_automation library config
        REMOTE_STATE_SA=$(echo "${temp}" | cut -d= -f2)
    fi

    temp=$(grep "tfstate_resource_id" "${library_config_information}")
    if [ ! -z "${temp}" ]
    then
        echo "tfstate_resource_id specified"
        tfstate_resource_id=$(echo "${temp}" | cut -d= -f2)
        if [ "${deployment_system}" != sap_deployer ]
        then
            tfstate_parameter=" -var tfstate_resource_id=${tfstate_resource_id}"
        fi
    fi

    temp=$(grep "deployer_tfstate_key" "${library_config_information}")
    if [ ! -z "${temp}" ]
    then
        # Deployer state was specified in ~/.sap_deployment_automation library config
        deployer_tfstate_key=$(echo "${temp}" | cut -d= -f2)
        
        if [ "${deployment_system}" != sap_deployer ]
        then
            deployer_tfstate_key_parameter=" -var deployer_tfstate_key=${deployer_tfstate_key}"
        else
            rm post_deployment.sh
        fi

        deployer_tfstate_key_exists=true

    fi

fi

if [ ! -n "${DEPLOYMENT_REPO_PATH}" ]; then
    option="DEPLOYMENT_REPO_PATH"
    missing
    exit -1
fi

if [ ! -n "${ARM_SUBSCRIPTION_ID}" ]; then
    option="ARM_SUBSCRIPTION_ID"
    missing
    exit -1
fi

if [ ! -n "${REMOTE_STATE_RG}" ]; then
    option="REMOTE_STATE_RG"
    missing
    exit -1
fi

if [ ! -n "${REMOTE_STATE_SA}" ]; then
    option="REMOTE_STATE_SA"
    missing
    exit -1
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

if [ -f backend.tf ]
then
    rm backend.tf
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
    rm stdout.az
    exit -1
else
    rm stdout.az
fi

check_output=0

if [ ! -d ./.terraform/ ]; 
then
    terraform init -upgrade=true -force-copy --backend-config "subscription_id=${ARM_SUBSCRIPTION_ID}" \
    --backend-config "resource_group_name=${REMOTE_STATE_RG}" \
    --backend-config "storage_account_name=${REMOTE_STATE_SA}" \
    --backend-config "container_name=tfstate" \
    --backend-config "key=${key}.terraform.tfstate" \
    $terraform_module_directory
else
    temp=$(grep "\"type\": \"local\"" .terraform/terraform.tfstate)
    if [ ! -z "${temp}" ]
    then
        echo "${REMOTE_STATE_SA}"
        terraform init -upgrade=true -force-copy --backend-config "subscription_id=${ARM_SUBSCRIPTION_ID}" \
        --backend-config "resource_group_name=${REMOTE_STATE_RG}" \
        --backend-config "storage_account_name=${REMOTE_STATE_SA}" \
        --backend-config "container_name=tfstate" \
        --backend-config "key=${key}.terraform.tfstate" \
        $terraform_module_directory
    else
        terraform init -upgrade=true
        check_output=1
    fi

fi

if [ 1 == $check_output ]
then
    outputs=$(terraform output)
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

        deployed_using_version=$(terraform output automation_version)
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

terraform plan -var-file=${parameterfile} $tfstate_parameter $landscape_tfstate_key_parameter $deployer_tfstate_key_parameter $terraform_module_directory > plan_output.log

if ! $new_deployment; then
    if grep "No changes" plan_output.log ; then
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo "#                           Infrastructure is up to date                                #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""
        rm plan_output.log

        if [ $deployment_system == sap_landscape ]
        then
            if [ $landscape_tfstate_key_exists == false ]
            then
                echo "landscape_tfstate_key=${key}.terraform.tfstate" >> $workload_config_information
                landscape_tfstate_key_exists=true
            fi
        fi
        exit 0
    fi
    if ! grep "0 to change, 0 to destroy" plan_output.log ; then
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

    terraform apply ${approve} -var-file=${parameterfile} $tfstate_parameter $landscape_tfstate_key_parameter $deployer_tfstate_key_parameter $terraform_module_directory
fi

if [ $deployment_system == sap_landscape ]
then
    if [ $landscape_tfstate_key_exists == false ]
    then
        sed -i /landscape_tfstate_key/d  "${workload_config_information}"

        echo "landscape_tfstate_key=${key}.terraform.tfstate" >> $workload_config_information
    fi
fi

exit 0