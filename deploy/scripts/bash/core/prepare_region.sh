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
recover=0

INPUT_ARGUMENTS=$(getopt -n prepare_region -o d:l:s:c:p:t:a:ifohr --longoptions deployer_parameter_file:,library_parameter_file:,subscription:,spn_id:,spn_secret:,tenant_id:,storageaccountname:,auto-approve,force,only_deployer,help,recover -- "$@")
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
        -a | --storageaccountname)                 REMOTE_STATE_SA="$2"             ; shift 2 ;;
        -f | --force)                              force=1                          ; shift ;;
        -o | --only_deployer)                      only_deployer=1                  ; shift ;;
        -r | --recover)                            recover=1                        ; shift ;;
        -i | --auto-approve)                       approve="--auto-approve"         ; shift ;;
        -h | --help)                               showhelp
        exit 3                           ; shift ;;
        --) shift; break ;;
    esac
done

this_ip=$(curl ipinfo.io/ip)

root_dirname=$(pwd)

if [ ! -z "$approve" ]; then
    approveparam=" -i"
fi

if [ -z "$deployer_parameter_file" ]; then
    missing_value='deployer parameter file'
    missing
    exit 2 #No such file or directory
fi

if [ -z "$library_parameter_file" ]; then
    missing_value='library parameter file'
    missing
    exit 2 #No such file or directory
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
    exit 2 #No such file or directory
fi

az --version >stdout.az 2>&1
az=$(grep "azure-cli" stdout.az)
if [ ! -n "${az}" ]; then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                          $boldreduscore Please install the Azure CLI $resetformatting                               #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    exit 2 #No such file or directory
fi

ext=$(echo ${deployer_parameter_file} | cut -d. -f2)

# Helper variables
if [ "${ext}" == json ]; then
    environment=$(jq --raw-output .infrastructure.environment "${deployer_parameter_file}")
    region=$(jq --raw-output .infrastructure.region "${deployer_parameter_file}")
else
    load_config_vars "${root_dirname}"/"${deployer_parameter_file}" "environment"
    load_config_vars "${root_dirname}"/"${deployer_parameter_file}" "location"
    region=$(echo ${location} | xargs)
fi


if [ ! -n "${environment}" ]; then
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                         $boldred  Incorrect parameter file. $resetformatting                                  #"
    echo "#                                                                                       #"
    echo "#                The file must contain the environment attribute!!                      #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    exit 64 #script usage wrong
fi

if [ ! -n "${region}" ]; then
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                          $boldred Incorrect parameter file. $resetformatting                                  #"
    echo "#                                                                                       #"
    echo "#              The file must contain the region/location attribute!!                    #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    exit 64                                                                                           #script usage wrong
fi

automation_config_directory=~/.sap_deployment_automation
generic_config_information="${automation_config_directory}"/config
deployer_config_information="${automation_config_directory}"/"${environment}""${region}"

#Plugins
if [ ! -d "$HOME/.terraform.d/plugin-cache" ]; then
    mkdir "$HOME/.terraform.d/plugin-cache"
fi
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"

if [ $force == 1 ]; then
    if [ -f "${deployer_config_information}" ]; then
        rm "${deployer_config_information}"
    fi
    rm -Rf .terraform terraform.tfstate*
    
fi

init "${automation_config_directory}" "${generic_config_information}" "${deployer_config_information}"

if [ ! -z "${subscription}" ]; then
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
    echo -e "#  $boldred Missing environment variables (DEPLOYMENT_REPO_PATH)!!! $resetformatting                            #"
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
if [ 37 != $templen ]; then
    arm_config_stored=0
fi

if [ ! -n "$ARM_SUBSCRIPTION_ID" ]; then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#  $boldred Missing environment variables (ARM_SUBSCRIPTION_ID)!!! $resetformatting                             #"
    echo "#                                                                                       #"
    echo "#   Please export the folloing variables:                                               #"
    echo "#      DEPLOYMENT_REPO_PATH (path to the repo folder (sap-hana))                        #"
    echo "#      ARM_SUBSCRIPTION_ID (subscription containing the state file storage account)     #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    exit 65                                                                                           #data format error
else
    if [ "${arm_config_stored}" != 0 ]; then
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
    echo -e "#                          $boldred Please login using az login! $resetformatting                               #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    if [ -f stdout.az ]; then
        rm stdout.az
    fi
    exit 67                                                                                             #addressee unknown
else
    if [ -f stdout.az ]; then
        rm stdout.az
    fi
    
    if [ ! -z "${subscription}" ]; then
        echo "Setting the subscription"
        az account set --sub "${subscription}"
        export ARM_SUBSCRIPTION_ID="${subscription}"
    fi
    
fi

step=0


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
set_executing_user_environment_variables "${spn_secret}"

load_config_vars "${deployer_config_information}" "step"


if [ $recover == 1 ]; then
    if [ -n $REMOTE_STATE_SA ]; then
        save_config_var "REMOTE_STATE_SA" "${deployer_config_information}"
        get_and_store_sa_details ${REMOTE_STATE_SA} "${deployer_config_information}"
        #Support running prepare_region on new host when the resources are already deployed
        step=3
        save_config_var "step" "${deployer_config_information}"
    fi
fi

curdir=$(pwd)
if [ 0 == $step ]; then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                          $cyan Bootstrapping the deployer $resetformatting                                 #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    
    #Persist the parameters
    if [ ! -z "$subscription" ]; then
        save_config_var "subscription" "${deployer_config_information}"
        kvsubscription=$subscription
        save_config_var "kvsubscription" "${deployer_config_information}"
    fi
    
    if [ ! -z "$client_id" ]; then
        save_config_var "client_id" "${deployer_config_information}"
    fi
    
    if [ ! -z "$tenant_id" ]; then
        save_config_var "tenant_id" "${deployer_config_information}"
    fi
    
    cd "${deployer_dirname}" || exit
    
    if [ $force == 1 ]; then
        rm -Rf .terraform terraform.tfstate*
    fi
    
    allParams=$(printf " -p %s %s" "${deployer_file_parametername}" "${approveparam}")
    
    "${DEPLOYMENT_REPO_PATH}"/deploy/scripts/install_deployer.sh $allParams
    if (($? > 0)); then
        exit $?
    fi
    
    step=1
    save_config_var "step" "${deployer_config_information}"


    cd "$root_dirname" || exit
    
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                         $cyan  Copying the parameterfiles $resetformatting                                 #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    
    ssh_timeout_s=10
    
    load_config_vars "${deployer_config_information}" "sshsecret"
    load_config_vars "${deployer_config_information}" "keyvault"
    load_config_vars "${deployer_config_information}" "deployer_public_ip_address"

    if [ "$this_ip" != "$deployer_public_ip_address" ] ; then
        # Only run this when not on deployer
        if [ ! -z ${sshsecret} ]
        then
            echo "#########################################################################################"
            echo "#                                                                                       #"
            echo -e "#                            $cyan Collecting secrets from KV $resetformatting                               #"
            echo "#                                                                                       #"
            echo "#########################################################################################"
            echo ""

            temp_file=$(mktemp)
            ppk=$(az keyvault secret show --vault-name "${keyvault}" --name "${sshsecret}" | jq -r .value)
            echo "${ppk}" > "${temp_file}"
            chmod 600 "${temp_file}"
            
            remote_deployer_dir="$HOME/Azure_SAP_Automated_Deployment/WORKSPACES/"$(dirname "$deployer_parameter_file")
            remote_library_dir="$HOME/Azure_SAP_Automated_Deployment/WORKSPACES/"$(dirname "$library_parameter_file")
            remote_config_dir="$HOME/.sap_deployment_automation"
            
            ssh -i "${temp_file}" -o StrictHostKeyChecking=no -o ConnectTimeout=10 azureadm@"${deployer_public_ip_address}" "mkdir -p ${remote_deployer_dir}"/.terraform
            scp -i "${temp_file}" -o StrictHostKeyChecking=no -o ConnectTimeout=120 "$deployer_parameter_file" azureadm@"${deployer_public_ip_address}":"${remote_deployer_dir}"/.
            scp -i "${temp_file}" -o StrictHostKeyChecking=no -o ConnectTimeout=120 "$(dirname "$deployer_parameter_file")"/.terraform/terraform.tfstate azureadm@"${deployer_public_ip_address}":"${remote_deployer_dir}"/.terraform/terraform.tfstate        
            scp -i "${temp_file}" -o StrictHostKeyChecking=no -o ConnectTimeout=120 "$(dirname "$deployer_parameter_file")"/terraform.tfstate azureadm@"${deployer_public_ip_address}":"${remote_deployer_dir}"/terraform.tfstate        
            
            ssh -i "${temp_file}" -o StrictHostKeyChecking=no -o ConnectTimeout=10 azureadm@"${deployer_public_ip_address}" " mkdir -p ${remote_library_dir}"/.terraform
            scp -i "${temp_file}" -o StrictHostKeyChecking=no -o ConnectTimeout=120 "$library_parameter_file" azureadm@"${deployer_public_ip_address}":"$remote_library_dir"/.
            
            ssh -i "${temp_file}" -o StrictHostKeyChecking=no -o ConnectTimeout=10 azureadm@"${deployer_public_ip_address}" "mkdir -p ${remote_config_dir}"
            scp -i "${temp_file}" -o StrictHostKeyChecking=no -o ConnectTimeout=120 "${deployer_config_information}" azureadm@"${deployer_public_ip_address}":"${remote_config_dir}"/.
            
            rm "${temp_file}"
        fi
    fi
    
else
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                          $cyan Deployer is bootstrapped $resetformatting                                   #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
fi

if [ 1 = "${only_deployer:-}" ]; then
    load_config_vars "${deployer_config_information}" deployer_public_ip_address
    echo ""
    echo -e "Please ${cyan}login${resetformatting} to the deployer node (${boldred}${deployer_public_ip_address}${resetformatting}) and re-run ${boldred}$(basename ${0})${resetformatting} to continue."
    unset TF_DATA_DIR
    printf -v secretname '%-40s' "${environment}"-client-id
    printf -v secretname2 '%-40s' "${environment}"-client-secret
    printf -v secretname3 '%-40s' "${environment}"-subscription-id
    printf -v secretname4 '%-40s' "${environment}"-tenant-id
    printf -v deployerpara '%-40s' "-d ${deployer_parameter_file}"
    printf -v librarypara '%-40s' "-l ${library_parameter_file}"

    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "# $cyan Please populate the keyvault: ${keyvault} $resetformatting                                   #"
    echo "#     with the following secrets:                                                       #"
    echo "#     - $secretname                                        #"
    echo "#     - $secretname2                                        #"
    echo "#     - $secretname3                                        #"
    echo "#     - $secretname4                                        #"
    echo "#                                                                                       #"
    echo "#  Once done please logon to the deployer and resume by running:                        #"
    echo "#                                                                                       #"
    echo "#    \$DEPLOYMENT_REPO_PATH/deploy/scripts/prepare_region.sh \                           #"
    echo "#    $deployerpara     #"
    echo "#    $librarypara                        #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""

    step=6
    save_config_var "step" "${deployer_config_information}"
    exit 0
fi

if [ 1 == $step ]; then
    secretname="${environment}"-client-id
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                          $cyan Validating keyvault access $resetformatting                                 #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    
    az keyvault secret show --name "$secretname" --vault "$keyvault" --only-show-errors 2>error.log
    if [ -s error.log ]; then
        if [ ! -z "$spn_secret" ]; then
            allParams=$(printf " -e %s -r %s -v %s --spn_secret %s " "${environment}" "${region}" "${keyvault}" "${spn_secret}")
            
            "${DEPLOYMENT_REPO_PATH}"/deploy/scripts/set_secrets.sh $allParams
            if (($? > 0)); then
                exit $?
            fi
        else
            read -p "Do you want to specify the SPN Details Y/N?" ans
            answer=${ans^^}
            if [ "$answer" == 'Y' ]; then
                allParams=$(printf " -e %s -r %s -v %s " "${environment}" "${region}" "${keyvault}" )

                #$allParams as an array (); array math can be done in shell, allowing dynamic parameter lists to be created
                #"${allParams[@]}" - quotes all elements of the array

                "${DEPLOYMENT_REPO_PATH}"/deploy/scripts/set_secrets.sh $allParams
                if (($? > 0)); then
                    exit $?
                fi
            fi
        fi
        
        if [ -f post_deployment.sh ]; then
            ./post_deployment.sh
            if (($? > 0)); then
                exit $?
            fi
        fi
        cd "${curdir}" || exit
        step=2
        save_config_var "step" "${deployer_config_information}"
        
    fi
fi
unset TF_DATA_DIR
cd "$root_dirname" || exit

if [ 2 == $step ]; then
    
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                          $cyan Bootstrapping the library $resetformatting                                  #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    
    relative_path="${root_dirname}"/"${library_dirname}"
    export TF_DATA_DIR="${relative_path}/.terraform"
    relative_path="${root_dirname}"/"${deployer_dirname}"
    
    cd "${library_dirname}" || exit
    
    if [ $force == 1 ]; then
        rm -Rf .terraform terraform.tfstate*
    fi
    
    allParams=$(printf " -p %s -d %s %s" "${library_file_parametername}" "${relative_path}" "${approveparam}")
    
    "${DEPLOYMENT_REPO_PATH}"/deploy/scripts/install_library.sh $allParams
    if (($? > 0)); then
        exit $?
    fi
    cd "${curdir}" || exit
    step=3
    save_config_var "step" "${deployer_config_information}"
else
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                           $cyan Library is bootstrapped $resetformatting                                   #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    
fi

unset TF_DATA_DIR
cd $root_dirname

if [ 3 == $step ]; then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                          $cyan Migrating the deployer state $resetformatting                               #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    
    cd "${deployer_dirname}" || exit
    
    # Remove the script file
    if [ -f post_deployment.sh ]; then
        rm post_deployment.sh
    fi
    allParams=$(printf " -p %s -t sap_deployer %s" "${deployer_file_parametername}" "${approveparam}")
    
    "${DEPLOYMENT_REPO_PATH}"/deploy/scripts/installer.sh $allParams
    if (($? > 0)); then
        exit $?
    fi
    cd "${curdir}" || exit
    step=4
    save_config_var "step" "${deployer_config_information}"
fi

unset TF_DATA_DIR
cd "$root_dirname" || exit

if [ 4 == $step ]; then
    
    echo ""
    
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                          $cyan Migrating the library state $resetformatting                                #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    
    cd "${library_dirname}" || exit
    allParams=$(printf " -p %s -t sap_library %s" "${library_file_parametername}" "${approveparam}")
    
    "${DEPLOYMENT_REPO_PATH}"/deploy/scripts/installer.sh $allParams
    if (($? > 0)); then
        exit $?
    fi
    cd "${curdir}" || exit
    step=5
    save_config_var "step" "${deployer_config_information}"
fi

if [ 5 == $step ]; then
    cd "${curdir}" || exit
    
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                         $cyan  Copying the parameterfiles $resetformatting                                 #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    
    ssh_timeout_s=10
    
    load_config_vars "${deployer_config_information}" "sshsecret"
    load_config_vars "${deployer_config_information}" "keyvault"
    load_config_vars "${deployer_config_information}" "deployer_public_ip_address"
    if [ "$this_ip" != "$deployer_public_ip_address" ] ; then
        # Only run this when not on deployer
    
        if [ ! -z ${sshsecret} ]
        then
            step=3
            save_config_var "step" "${deployer_config_information}"
            printf "%s\n" "Collecting secrets from KV"
            temp_file=$(mktemp)
            ppk=$(az keyvault secret show --vault-name "${keyvault}" --name "${sshsecret}" | jq -r .value)
            echo "${ppk}" > "${temp_file}"
            chmod 600 "${temp_file}"

            remote_deployer_dir="/home/azureadm/Azure_SAP_Automated_Deployment/WORKSPACES/"$(dirname "$deployer_parameter_file")
            remote_library_dir="/home/azureadm/Azure_SAP_Automated_Deployment/WORKSPACES/"$(dirname "$library_parameter_file")
            remote_config_dir="/home/azureadm/.sap_deployment_automation"
            
            ssh -i "${temp_file}" -o StrictHostKeyChecking=no -o ConnectTimeout=10 azureadm@"${deployer_public_ip_address}" "mkdir -p ${remote_deployer_dir}"/.terraform
            scp -i "${temp_file}" -o StrictHostKeyChecking=no -o ConnectTimeout=120 "$deployer_parameter_file" azureadm@"${deployer_public_ip_address}":"${remote_deployer_dir}"/.
            scp -i "${temp_file}" -o StrictHostKeyChecking=no -o ConnectTimeout=120 "$(dirname "$deployer_parameter_file")"/.terraform/terraform.tfstate azureadm@"${deployer_public_ip_address}":"${remote_deployer_dir}"/.terraform/terraform.tfstate        
            scp -i "${temp_file}" -o StrictHostKeyChecking=no -o ConnectTimeout=120 "$(dirname "$deployer_parameter_file")"/terraform.tfstate azureadm@"${deployer_public_ip_address}":"${remote_deployer_dir}"/terraform.tfstate        
            
            ssh -i "${temp_file}" -o StrictHostKeyChecking=no -o ConnectTimeout=10 azureadm@"${deployer_public_ip_address}" " mkdir -p ${remote_library_dir}"/.terraform
            scp -i "${temp_file}"  -o StrictHostKeyChecking=no -o ConnectTimeout=120 "$(dirname "$deployer_parameter_file")"/.terraform/terraform.tfstate azureadm@"${deployer_public_ip_address}":"${remote_deployer_dir}"/.
            scp -i "${temp_file}" -o StrictHostKeyChecking=no -o ConnectTimeout=120 "$library_parameter_file" azureadm@"${deployer_public_ip_address}":"$remote_library_dir"/.
            
            ssh -i "${temp_file}" -o StrictHostKeyChecking=no -o ConnectTimeout=10 azureadm@"${deployer_public_ip_address}" "mkdir -p ${remote_config_dir}"
            scp -i "${temp_file}" -o StrictHostKeyChecking=no -o ConnectTimeout=120 "${deployer_config_information}" azureadm@"${deployer_public_ip_address}":"${remote_config_dir}"/.
            
            rm "${temp_file}"
        else
            step=3
            save_config_var "step" ${deployer_config_information}
            
            
        fi
    else
        step=3
        save_config_var "step" ${deployer_config_information}
    fi
fi

unset TF_DATA_DIR

exit 0
