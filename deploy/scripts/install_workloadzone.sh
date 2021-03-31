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
        d) deployer_tfstate_key=${OPTARG};;
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

deployer_tfstate_key_parameter=""
deployer_tfstate_key_exists=false
landscape_tfstate_key=""
landscape_tfstate_key_parameter=""
landscape_tfstate_key_exists=false

deployment_system=sap_landscape

workload_dirname=$(dirname "${parameterfile}")
workload_file_parametername=$(basename "${parameterfile}")


# Read environment
environment=$(cat "${parameterfile}" | jq .infrastructure.environment | tr -d \")
region=$(cat "${parameterfile}" | jq .infrastructure.region | tr -d \")
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
workload_config_information="${automation_config_directory}""${environment}""${region}"
touch $workload_config_information

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


read -p "Do you want to specify the Workload SPN Details Y/N?"  ans
answer=${ans^^}
if [ $answer == 'Y' ]; then
    temp=$(grep "keyvault=" $workload_config_information)
    if [ ! -z $temp ]
    then
        # Key vault was specified in ~/.sap_deployment_automation in the deployer file
        keyvault_name=$(echo $temp | cut -d= -f2 | tr -d \" | xargs)
        keyvault_param=$(printf " -v %s " $keyvault_name)
    fi
    
    env_param=$(printf " -e %s " "${environment}")
    region_param=$(printf " -r %s " "${region}")
    
    allParams="${env_param}""${keyvault_param}""${region_param}"
    
    "${DEPLOYMENT_REPO_PATH}"deploy/scripts/set_secrets.sh $allParams
    if [ $? -eq 255 ]
    then
        exit $?
    fi
fi


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
        echo "ARM_SUBSCRIPTION_ID=${ARM_SUBSCRIPTION_ID}" >> "${workload_config_information}"
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
    
    temp=$(grep "REMOTE_STATE_RG" "${workload_config_information}")
    if [ ! -z "${temp}" ]
    then
        # Remote state storage group was specified in ~/.sap_deployment_automation library config
        REMOTE_STATE_RG=$(echo "${temp}" | cut -d= -f2 | tr -d \" | xargs)
    fi
    
    temp=$(grep "REMOTE_STATE_SA" "${workload_config_information}")
    if [ ! -z "${temp}" ]
    then
        # Remmote state storage group was specified in ~/.sap_deployment_automation library config
        REMOTE_STATE_SA=$(echo "${temp}" | cut -d= -f2 | tr -d \" | xargs)
    fi
    
    temp=$(grep "tfstate_resource_id" "${workload_config_information}")
    if [ ! -z "${temp}" ]
    then
        tfstate_resource_id=$(echo "${temp}" | cut -d= -f2 | tr -d \" | xargs)
        if [ "${deployment_system}" != sap_deployer ]
        then
            tfstate_parameter=" -var tfstate_resource_id=${tfstate_resource_id}"
        fi
    fi
    
    if [ -z "${deployer_tfstate_key}" ]
    then
        temp=$(grep "deployer_tfstate_key" "${workload_config_information}")
        if [ ! -z "${temp}" ]
        then
            # Deployer state was specified in ~/.sap_deployment_automation library config
            deployer_tfstate_key=$(echo "${temp}" | cut -d= -f2 | tr -d \" | xargs)
            deployer_tfstate_key_parameter=" -var deployer_tfstate_key=${deployer_tfstate_key}"
            
            deployer_tfstate_key_exists=true
        else
            # Ask for deployer environment name and try to read the deployer state file and resource group details from the configuration file
            read -p "Deployer environment name: " deployer_environment
            deployer_config_information="${automation_config_directory}""${deployer_environment}""${region}"
            temp=$(grep "deployer_tfstate_key" "${deployer_config_information}")
            if [ ! -z "${temp}" ]
            then
                # Deployer state was specified in ~/.sap_deployment_automation library config
                deployer_tfstate_key=$(echo "${temp}" | cut -d= -f2 | tr -d \" | xargs)
                deployer_tfstate_key_parameter=" -var deployer_tfstate_key=${deployer_tfstate_key}"
                deployer_tfstate_key_exists=true

                temp=$(grep "REMOTE_STATE_RG" "${deployer_config_information}")
                if [ ! -z "${temp}" ]
                then
                    # Remote state storage group was specified in ~/.sap_deployment_automation library config
                    REMOTE_STATE_RG=$(echo "${temp}" | cut -d= -f2 | tr -d \" | xargs)
                fi
                
                temp=$(grep "REMOTE_STATE_SA" "${deployer_config_information}")
                if [ ! -z "${temp}" ]
                then
                    # Remmote state storage group was specified in ~/.sap_deployment_automation library config
                    REMOTE_STATE_SA=$(echo "${temp}" | cut -d= -f2 | tr -d \" | xargs)
                fi
                
                temp=$(grep "tfstate_resource_id" "${deployer_config_information}")
                if [ ! -z "${temp}" ]
                then
                    tfstate_resource_id=$(echo "${temp}" | cut -d= -f2 | tr -d \" | xargs)
                    if [ "${deployment_system}" != sap_deployer ]
                    then
                        tfstate_parameter=" -var tfstate_resource_id=${tfstate_resource_id}"
                    fi
                fi

                sed -i /REMOTE_STATE_SA/d  "${workload_config_information}"
                sed -i /REMOTE_STATE_RG/d  "${workload_config_information}"
                sed -i /tfstate_resource_id/d  "${workload_config_information}"
                sed -i /STATE_SUBSCRIPTION/d  "${workload_config_information}"
                sed -i /deployer_tfstate_key/d  "${workload_config_information}"
  
                echo "deployer_tfstate_key=${deployer_tfstate_key}" >> "${workload_config_information}"
                
                echo "REMOTE_STATE_SA=${REMOTE_STATE_SA}" >> "${workload_config_information}"
                echo "REMOTE_STATE_RG=${REMOTE_STATE_RG}" >> "${workload_config_information}"
                echo "tfstate_resource_id=${tfstate_resource_id}" >> "${workload_config_information}"
                STATE_SUBSCRIPTION=$(echo $tfstate_resource_id | cut -d/ -f3 | tr -d \" | xargs)
                
                echo "STATE_SUBSCRIPTION=${STATE_SUBSCRIPTION}" >> "${workload_config_information}"

                
            else
                
                read -p "Deployer state file name (empty for no deployer): "  deployer_tfstate_key
                deployer_tfstate_key_parameter=" -var deployer_tfstate_key=${deployer_tfstate_key}"
                sed -i /deployer_tfstate_key/d  "${workload_config_information}"
                echo "deployer_tfstate_key=${deployer_tfstate_key}" >> "${workload_config_information}"
            fi
            
        fi
    else
        deployer_tfstate_key_parameter=" -var deployer_tfstate_key=${deployer_tfstate_key}"
        sed -i /deployer_tfstate_key/d  "${workload_config_information}"
        echo "deployer_tfstate_key=${deployer_tfstate_key}" >> "${workload_config_information}"
        
    fi
    
fi

if [ ! -n "${DEPLOYMENT_REPO_PATH}" ]; then
    option="DEPLOYMENT_REPO_PATH"
    missing
    exit -1
fi

if [ ! -n "${ARM_SUBSCRIPTION_ID}" ]; then
    read -p "Please provide the subscription id for the workload:" ARM_SUBSCRIPTION_ID
    echo "subscription=${ARM_SUBSCRIPTION_ID}" >> "${workload_config_information}"
fi

if [ ! -n "${REMOTE_STATE_SA}" ]; then
    option="REMOTE_STATE_SA"
    read -p "Remote state storage account name:"  REMOTE_STATE_SA
    REMOTE_STATE_RG=$(az resource list --name ${REMOTE_STATE_SA} | jq .[0].resourceGroup  | tr -d \" | xargs)
    tfstate_resource_id=$(az resource list --name ${REMOTE_STATE_SA} | jq .[0].id  | tr -d \" | xargs)
    
    sed -i /REMOTE_STATE_SA/d  "${workload_config_information}"
    sed -i /REMOTE_STATE_RG/d  "${workload_config_information}"
    sed -i /tfstate_resource_id/d  "${workload_config_information}"
    sed -i /STATE_SUBSCRIPTION/d  "${workload_config_information}"
    
    echo "REMOTE_STATE_SA=${REMOTE_STATE_SA}" >> "${workload_config_information}"
    echo "REMOTE_STATE_RG=${REMOTE_STATE_RG}" >> "${workload_config_information}"
    echo "tfstate_resource_id=${tfstate_resource_id}" >> "${workload_config_information}"
    STATE_SUBSCRIPTION=$(echo $tfstate_resource_id | cut -d/ -f3 | tr -d \" | xargs)
    
    echo "STATE_SUBSCRIPTION=${STATE_SUBSCRIPTION}" >> "${workload_config_information}"
    
    tfstate_parameter=" -var tfstate_resource_id=${tfstate_resource_id}"
    
fi


if [ ! -n "${REMOTE_STATE_RG}" ]; then
    if [  -n "${REMOTE_STATE_SA}" ]; then
        REMOTE_STATE_RG=$(az resource list --name ${REMOTE_STATE_SA} | jq .[0].resourceGroup  | tr -d \" | xargs)
        tfstate_resource_id=$(az resource list --name ${REMOTE_STATE_SA} | jq .[0].id  | tr -d \" | xargs)
        
        sed -i /REMOTE_STATE_SA/d  "${workload_config_information}"
        sed -i /REMOTE_STATE_RG/d  "${workload_config_information}"
        sed -i /tfstate_resource_id/d  "${workload_config_information}"
        sed -i /STATE_SUBSCRIPTION/d  "${workload_config_information}"
        
        echo "REMOTE_STATE_SA=${REMOTE_STATE_SA}" >> "${workload_config_information}"
        echo "REMOTE_STATE_RG=${REMOTE_STATE_RG}" >> "${workload_config_information}"
        echo "tfstate_resource_id=${tfstate_resource_id}" >> "${workload_config_information}"
        STATE_SUBSCRIPTION=$(echo $tfstate_resource_id | cut -d/ -f3 | tr -d \" | xargs)
        echo "STATE_SUBSCRIPTION=${STATE_SUBSCRIPTION}" >> "${workload_config_information}"
        
        tfstate_parameter=" -var tfstate_resource_id=${tfstate_resource_id}"
    else
        
        option="REMOTE_STATE_RG"
        read -p "Remote state resource group name:"  REMOTE_STATE_RG
        echo "REMOTE_STATE_RG=${REMOTE_STATE_RG}" >> "${workload_config_information}"
    fi
fi

echo "tfstate_resource_id=${tfstate_resource_id}"

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
        
        terraform init -upgrade=true -force-copy --backend-config "subscription_id=${ARM_SUBSCRIPTION_ID}" \
        --backend-config "resource_group_name=${REMOTE_STATE_RG}" \
        --backend-config "storage_account_name=${REMOTE_STATE_SA}" \
        --backend-config "container_name=tfstate" \
        --backend-config "key=${key}.terraform.tfstate" \
        $terraform_module_directory
    else
        terraform init -upgrade=true $terraform_module_directory
        check_output=1
    fi
    
fi
cat <<EOF > backend.tf
####################################################
# To overcome terraform issue                      #
####################################################
terraform {
    backend "azurerm" {}
}
EOF
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
echo $tfstate_parameter
echo $deployer_tfstate_key_parameter
echo $terraform_module_directory
terraform plan -var-file=${parameterfile} $tfstate_parameter $deployer_tfstate_key_parameter $terraform_module_directory > plan_output.log

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