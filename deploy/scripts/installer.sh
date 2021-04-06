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
environment=$(cat "${parameterfile}" | jq .infrastructure.environment | tr -d \")
region=$(cat "${parameterfile}" | jq .infrastructure.region | tr -d \")

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
system_config_information="${automation_config_directory}""${environment}""${region}"

if [ ! -d ${automation_config_directory} ]
then
    # No configuration directory exists
    mkdir $automation_config_directory
    touch "${generic_config_information}"
    touch "${system_config_information}"
    if [ -n "${DEPLOYMENT_REPO_PATH}" ]; then
        # Store repo path in ~/.sap_deployment_automation/config
        echo "DEPLOYMENT_REPO_PATH=${DEPLOYMENT_REPO_PATH}" >> "${generic_config_information}"
        config_stored=1
    fi
    if [ -n "$ARM_SUBSCRIPTION_ID" ]; then
        # Store ARM Subscription info in ~/.sap_deployment_automation
        echo "ARM_SUBSCRIPTION_ID=${ARM_SUBSCRIPTION_ID}" >> "${system_config_information}"
        arm_config_stored=1
    fi
else
    temp=$(grep  -m1 "DEPLOYMENT_REPO_PATH" "${generic_config_information}")
    if [ ! -z "${temp}" ]
    then
        # Repo path was specified in ~/.sap_deployment_automation/config
        DEPLOYMENT_REPO_PATH=$(echo "${temp}" | cut -d= -f2 | xargs)
        config_stored=1
    else
        config_stored=0
    fi
    
    temp=$(grep -m1 "REMOTE_STATE_RG" "${system_config_information}")
    if [ ! -z "${temp}" ]
    then
        # Remote state storage group was specified in ~/.sap_deployment_automation library config
        REMOTE_STATE_RG=$(echo "${temp}" | cut -d= -f2 | tr -d \" | xargs)
    fi
    
    temp=$(grep -m1 "REMOTE_STATE_SA" "${system_config_information}")
    if [ ! -z "${temp}" ]
    then
        # Remote state storage group was specified in ~/.sap_deployment_automation library config
        REMOTE_STATE_SA=$(echo "${temp}" | cut -d= -f2 | tr -d \" | xargs)
    fi
    
    temp=$(grep -m1 "subscription=" "${system_config_information}")
    
    if [ ! -z "${temp}" ]
    then
        # Remote state storage group was specified in ~/.sap_deployment_automation library config
        ARM_SUBSCRIPTION_ID=$(echo "${temp}" | cut -d= -f2 | tr -d \" | xargs)
    fi
    
    STATE_SUBSCRIPTION=${ARM_SUBSCRIPTION_ID}
    
    temp=$(grep -m1 "tfstate_resource_id" "${system_config_information}")
    if [ ! -z "${temp}" ]
    then
        tfstate_resource_id=$(echo "${temp}" | cut -d= -f2 | tr -d \" | xargs)
        if [ "${deployment_system}" != sap_deployer ]
        then
            tfstate_parameter=" -var tfstate_resource_id=${tfstate_resource_id}"
        fi
    fi
    
    temp=$(grep -m1 "STATE_SUBSCRIPTION" "${system_config_information}")
    if [ ! -z "${temp}" ]
    then
        STATE_SUBSCRIPTION=$(echo "${temp}" | cut -d= -f2 | tr -d \" | xargs)
    fi
    
    deployer_tfstate_key_parameter=''
    if [ "${deployment_system}" != sap_deployer ]
    then
        temp=$(grep -m1 "deployer_tfstate_key" "${system_config_information}")
        if [ ! -z "${temp}" ]
        then
            # Deployer state was specified in ~/.sap_deployment_automation library config
            deployer_tfstate_key=$(echo "${temp}" | cut -d= -f2 | tr -d \" | xargs)
            if [ ! -n "$=${deployer_tfstate_key}" ]; then
                deployer_tfstate_key_parameter=" "
            else
                deployer_tfstate_key_parameter=" -var deployer_tfstate_key=${deployer_tfstate_key}"
                deployer_tfstate_key_exists=true
            fi
        else
            if [ -f post_deployment.sh ]
            then
                rm post_deployment.sh
            fi
            
            deployer_tfstate_key_exists=true
        fi
    fi
    
    landscape_tfstate_key_parameter=''
    if [ $deployment_system == sap_system ]
    then
        temp=$(grep -m1 "landscape_tfstate_key" "${system_config_information}")
        if [ ! -z "${temp}" ]
        then
            # Landscape state was specified in ~/.sap_deployment_automation workload configuration
            landscape_tfstate_key=$(echo "${temp}" | cut -d= -f2 | tr -d \" | xargs)
            
            landscape_tfstate_key_parameter=" -var landscape_tfstate_key=${landscape_tfstate_key}"
            landscape_tfstate_key_exists=true
        else
            read -p "Workload terraform statefile name :" landscape_tfstate_key
            landscape_tfstate_key_parameter=" -var landscape_tfstate_key=${landscape_tfstate_key}"
            landscape_tfstate_key_exists=true
            sed -i /landscape_tfstate_key/d  "${system_config_information}"
            echo "landscape_tfstate_key=${landscape_tfstate_key}" >> $system_config_information
            
            landscape_tfstate_key_exists=true
        fi
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

if [ ! -n "${REMOTE_STATE_SA}" ]; then
    option="REMOTE_STATE_SA"
    read -p "Terraform state storage account name:"  REMOTE_STATE_SA
    REMOTE_STATE_RG=$(az resource list --name ${REMOTE_STATE_SA} | jq .[0].resourceGroup  | tr -d \" | xargs)
    tfstate_resource_id=$(az resource list --name ${REMOTE_STATE_SA} | jq .[0].id  | tr -d \" | xargs)
    
    sed -i /REMOTE_STATE_SA/d  "${system_config_information}"
    sed -i /REMOTE_STATE_RG/d  "${system_config_information}"
    sed -i /tfstate_resource_id/d  "${system_config_information}"
    sed -i /STATE_SUBSCRIPTION/d  "${system_config_information}"
    
    echo "REMOTE_STATE_SA=${REMOTE_STATE_SA}" >> "${system_config_information}"
    echo "REMOTE_STATE_RG=${REMOTE_STATE_RG}" >> "${system_config_information}"
    echo "tfstate_resource_id=${tfstate_resource_id}" >> "${system_config_information}"
    
    STATE_SUBSCRIPTION=$(echo $tfstate_resource_id | cut -d/ -f3 | tr -d \" | xargs)
    echo "STATE_SUBSCRIPTION=${STATE_SUBSCRIPTION}" >> "${system_config_information}"
    
    if [ "${deployment_system}" != sap_deployer ]
    then
        tfstate_parameter=" -var tfstate_resource_id=${tfstate_resource_id}"
    fi
    
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

check_output=0

cat <<EOF > backend.tf
####################################################
# To overcome terraform issue                      #
####################################################
terraform {
    backend "azurerm" {}
}
EOF

if [ ! -d ./.terraform/ ];
then
    terraform init -upgrade=true -force-copy \
    --backend-config "subscription_id=${STATE_SUBSCRIPTION}" \
    --backend-config "resource_group_name=${REMOTE_STATE_RG}" \
    --backend-config "storage_account_name=${REMOTE_STATE_SA}" \
    --backend-config "container_name=tfstate" \
    --backend-config "key=${key}.terraform.tfstate" \
    $terraform_module_directory
else
    temp=$(grep "\"type\": \"local\"" .terraform/terraform.tfstate)
    if [ ! -z "${temp}" ]
    then
        terraform init -upgrade=true -force-copy \
        --backend-config "subscription_id=${STATE_SUBSCRIPTION}" \
        --backend-config "resource_group_name=${REMOTE_STATE_RG}" \
        --backend-config "storage_account_name=${REMOTE_STATE_SA}" \
        --backend-config "container_name=tfstate" \
        --backend-config "key=${key}.terraform.tfstate" \
        $terraform_module_directory
    else
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo "#             The system has already been deployed and the statefile is in Azure        #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""
        read -p "Do you want to redeploy Y/N?"  ans
        answer=${ans^^}
        if [ $answer == 'Y' ]; then
            ok_to_proceed=true
        else
            exit 1
        fi
        
        terraform init -upgrade=true -var-file="${parameterfile}" $terraform_module_directory
        check_output=1
        
    fi
fi

if [ 1 == $check_output ]
then
    outputs=$(terraform output )
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

terraform plan -var-file=$parameterfile $tfstate_parameter $landscape_tfstate_key_parameter $deployer_tfstate_key_parameter $terraform_module_directory > plan_output.log

if ! $new_deployment; then
    str1=$(grep "0 to add, 0 to change, 0 to destroy" plan_output.log)
    str2=$(grep "No changes" plan_output.log)
    if [ ! -n "$str1"] || [ ! -n "$str2" ]; then
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo "#                           Infrastructure is up to date                                #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""
        rm plan_output.log
        
        if [ $deployment_system == sap_deployer ]
        then
            if [ $deployer_tfstate_key_exists == false ]
            then
                echo "Saving the deployer state file name"
                echo "deployer_tfstate_key=${key}.terraform.tfstate" >> $system_config_information
                deployer_tfstate_key_exists=true
            fi
        fi
        if [ $deployment_system == sap_landscape ]
        then
            if [ $landscape_tfstate_key_exists == false ]
            then
                echo "landscape_tfstate_key=${key}.terraform.tfstate" >> $system_config_information
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

if [ $deployment_system == sap_deployer ]
then
    echo $deployer_tfstate_key_exists
    if [ $deployer_tfstate_key_exists == false ]
    then
        sed -i /deployer_tfstate_key/d  "${system_config_information}"
        echo "deployer_tfstate_key=${key}.terraform.tfstate" >> $system_config_information
    fi
fi

if [ $deployment_system == sap_landscape ]
then
    if [ $landscape_tfstate_key_exists == false ]
    then
        sed -i /landscape_tfstate_key/d  "${system_config_information}"
        echo "landscape_tfstate_key=${key}.terraform.tfstate" >> $system_config_information
    fi
fi

if [ $deployment_system == sap_library ]
then
    
    REMOTE_STATE_RG=$(terraform output remote_state_resource_group_name | tr -d \")
    temp=$(echo "${REMOTE_STATE_RG}" | grep -m1 "Warning")
    if [ -z "${temp}" ]
    then
        temp=$(echo "${REMOTE_STATE_RG}" | grep -m1 "Backend reinitialization required")
        if [ -z "${temp}" ]
        then
            sed -i /REMOTE_STATE_RG/d  "${system_config_information}"
            echo "REMOTE_STATE_RG=${REMOTE_STATE_RG}" >> "${system_config_information}"
        fi
    fi
    
    REMOTE_STATE_SA=$(terraform output remote_state_storage_account_name| tr -d \")
    temp=$(echo "${REMOTE_STATE_SA}" | grep -m1 "Warning")
    if [ -z "${temp}" ]
    then
        temp=$(echo "${REMOTE_STATE_SA}" | grep -m1 "Backend reinitialization required")
        if [ -z "${temp}" ]
        then
            sed -i /REMOTE_STATE_SA/d  "${system_config_information}"
            echo "REMOTE_STATE_SA=${REMOTE_STATE_SA}" >> ${system_config_information}
        fi
    fi
    
    tfstate_resource_id=$(terraform output tfstate_resource_id| tr -d \")
    temp=$(echo "${tfstate_resource_id}" | grep -m1 "Warning" -m1 )
    if [ -z "${temp}" ]
    then
        temp=$(echo $tfstate_resource_id | grep -m1 "Backend reinitialization required" -m1 )
        if [ -z $temp ]
        then
            sed -i /tfstate_resource_id/d  "${system_config_information}"
            sed -i /STATE_SUBSCRIPTION/d  "${system_config_information}"
            STATE_SUBSCRIPTION=$(echo $tfstate_resource_id | cut -d/ -f3 | tr -d \" | xargs)
            echo "tfstate_resource_id=${tfstate_resource_id}" >> "${system_config_information}"
            echo "STATE_SUBSCRIPTION=${STATE_SUBSCRIPTION}" >> "${system_config_information}"
        fi
    fi
fi


exit 0
