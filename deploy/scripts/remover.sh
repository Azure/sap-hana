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
    echo "#   Usage: remover.sh                                                                 #"
    echo "#    -p parameter file                                                                  #"
    echo "#    -h Show help                                                                       #"
    echo "#                                                                                       #"
    echo "#   Example:                                                                            #"
    echo "#                                                                                       #"
    echo "#   [REPO-ROOT]deploy/scripts/install_deployer.sh \                                     #"
    echo "#      -p PROD-WEEU-DEP00-INFRASTRUCTURE.json \                                         #"
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
        t) deployment_system=${OPTARG};;
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

parameterfile_name=$(basename "${parameterfile}")


# Read environment
environment=$(grep "environment" "${parameterfile}" -m1  | cut -d: -f2 | cut -d, -f1 | tr -d \")
region=$(grep "region" "${parameterfile}" -m1  | cut -d: -f2 | cut -d, -f1 | tr -d \")

key=$(echo "${parameterfile_name}" | cut -d. -f1)

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

    temp=$(grep "landscape_tfstate_key" "${workload_config_information}")
    if [ ! -z "${temp}" ]
    then
        # Landscape state was specified in ~/.sap_deployment_automation library config
        landscape_tfstate_key=$(echo "${temp}" | cut -d= -f2)

        if [ $deployment_system == sap_system ]
        then
            landscape_tfstate_key_parameter=" -var landscape_tfstate_key=${landscape_tfstate_key}"
        fi
        landscape_tfstate_key_exists=true
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

echo $terraform_module_directory

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


echo ""
echo "#########################################################################################"
echo "#                                                                                       #"
echo "#                             Running Terraform apply                                   #"
echo "#                                                                                       #"
echo "#########################################################################################"
echo ""

terraform destroy -var-file=${parameterfile} $tfstate_parameter $landscape_tfstate_key_parameter $deployer_tfstate_key_parameter $terraform_module_directory

exit 0