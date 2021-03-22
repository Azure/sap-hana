#!/bin/bash

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
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#                                                                                       #" 
    echo "#   This file contains the logic to prepare an Azure region to support the              #" 
    echo "#   SAP Deployment Automation by preparing the deployer and the library.                #" 
    echo "#   The script experts the following exports:                                           #" 
    echo "#                                                                                       #" 
    echo "#     ARM_SUBSCRIPTION_ID to specify which subscription to deploy to                    #" 
    echo "#     DEPLOYMENT_REPO_PATH the path to the folder containing the cloned sap-hana        #" 
    echo "#                                                                                       #" 
    echo "#   The script is to be run from a parent folder to the folders containing              #" 
    echo "#   the json parameter files for the deployer, the library and the environment.         #" 
    echo "#                                                                                       #" 
    echo "#   The script will persist the parameters needed between the executions in the         #" 
    echo "#   ~/.sap_deployment_automation folder                                                 #" 
    echo "#                                                                                       #" 
    echo "#                                                                                       #" 
    echo "#   Usage: prepare_region.sh                                                            #"
    echo "#    -d deployer parameter file                                                         #"
    echo "#    -l library parameter file                                                          #"
    echo "#    -h Show help                                                                       #"
    echo "#                                                                                       #" 
    echo "#   Example:                                                                            #" 
    echo "#                                                                                       #" 
    echo "#   [REPO-ROOT]deploy/scripts/install_environment.sh \                                  #"
	echo "#      -d DEPLOYER/PROD-WEEU-DEP00-INFRASTRUCTURE/PROD-WEEU-DEP00-INFRASTRUCTURE.json \ #"
	echo "#      -l LIBRARY/PROD-WEEU-SAP_LIBRARY/PROD-WEEU-SAP_LIBRARY.json \                    #"
    echo "#                                                                                       #" 
    echo "#                                                                                       #" 
    echo "#########################################################################################"
}

function missing {
    printf -v val '%-40s' "$missing_value"
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #" 
    echo "#   Missing : ${val}                                  #"
    echo "#                                                                                       #" 
    echo "#   Usage: prepare_region.sh                                                            #"
    echo "#      -d deployer parameter file                                                       #"
    echo "#      -l library parameter file                                                        #"
    echo "#      -h Show help                                                                     #"
    echo "#                                                                                       #" 
    echo "#########################################################################################"

}

interactive=false

while getopts ":d:l:e:h" option; do
    case "${option}" in
        d) deployer_parameter_file=${OPTARG};;
        l) library_parameter_file=${OPTARG};;
        h) showhelp
           exit 3
           ;;
        ?) echo "Invalid option: -${OPTARG}."
           exit 2
           ;; 
    esac
done
if [ -z $deployer_parameter_file ]; then
    missing_value='deployer parameter file'
    missing
    exit -1
fi

echo $deployer_parameter_file

if [ -z $library_parameter_file ]; then
    missing_value='library parameter file'
    missing
    exit -1
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
    exit -1
fi

if [ ! -n "$DEPLOYMENT_REPO_PATH" ]; then
    echo ""
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
    exit -1
fi

# Check terraform
tf=$(terraform -version | grep Terraform)
if [ ! -n "$tf" ]; then 
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #" 
    echo "#                           Please install Terraform                                    #"
    echo "#                                                                                       #" 
    echo "#########################################################################################"
    echo ""
    exit -1
fi


az --version > stdout.az 2>&1
az=$(grep "azure-cli" stdout.az)
if [ ! -n "${az}" ]; then 
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #" 
    echo "#                           Please install the Azure CLI                                #"
    echo "#                                                                                       #" 
    echo "#########################################################################################"
    echo ""
    exit -1
fi


# Helper variables

automation_config_directory=~/.sap_deployment_automation/
generic_config_information="${automation_config_directory}"config
deployer_config_information="${automation_config_directory}""${region}"

if [ ! -d "${automation_config_directory}" ]
then
    # No configuration directory exists
    mkdir "${automation_config_directory}"
    touch "${deployer_config_information}
    touch "${generic_config_information}
    if [ -n "${DEPLOYMENT_REPO_PATH}" ]; then
        # Store repo path in ~/.sap_deployment_automation/config
        echo "DEPLOYMENT_REPO_PATH=${DEPLOYMENT_REPO_PATH}" >> "${generic_config_information}"
        config_stored=true
    fi
    if [ -n "$ARM_SUBSCRIPTION_ID" ]; then
        # Store ARM Subscription info in ~/.sap_deployment_automation
        echo "ARM_SUBSCRIPTION_ID=${ARM_SUBSCRIPTION_ID}" >> $deployer_config_information
        arm_config_stored=true
    fi

else
    temp=$(grep "DEPLOYMENT_REPO_PATH" "${generic_config_information}")
    if [ $temp ]
    then
        # Repo path was specified in ~/.sap_deployment_automation/config
        DEPLOYMENT_REPO_PATH=$(echo "${temp}" | cut -d= -f2)
        config_stored=true
    fi
fi

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
else
    if [ $config_stored == false ]
    then
        echo "DEPLOYMENT_REPO_PATH=${DEPLOYMENT_REPO_PATH}" >> ${automation_config_directory}config
    fi
fi

temp=$(grep "ARM_SUBSCRIPTION_ID" $deployer_config_information | cut -d= -f2)
templen=$(echo $temp | wc -c)
# Subscription length is 37

if [ 37 == $templen ] 
then
    echo "Reading the configuration"
    # ARM_SUBSCRIPTION_ID was specified in ~/.sap_deployment_automation/configuration file for deployer
    ARM_SUBSCRIPTION_ID="${temp}"
    arm_config_stored=true
else    
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
else
    if [  $arm_config_stored  == false ]
    then
        echo "Storing the configuration"
        sed -i /ARM_SUBSCRIPTION_ID/d  "${deployer_config_information}"
        echo "ARM_SUBSCRIPTION_ID=${ARM_SUBSCRIPTION_ID}" >> "${deployer_config_information}"
    fi
fi



deployer_dirname=$(dirname "${deployer_parameter_file}")
deployer_file_parametername=$(basename "${deployer_parameter_file}")

# Read environment
environment=$(cat "${parameterfile}" | jq .infrastructure.environment | tr -d \")
region=$(cat "${parameterfile}" | jq .infrastructure.region | tr -d \")

deployer_key=$(echo "${deployer_file_parametername}" | cut -d. -f1)
library_config_information="${automation_config_directory}""${region}"
touch $library_config_information

library_dirname=$(dirname "${library_parameter_file}")
library_file_parametername=$(basename "${library_parameter_file}")

#Calculate the depth of the library json folder relative to the root folder from which the code is called
readarray -d '/' -t levels<<<"${library_dirname}"
top=${#levels[@]}
relative_path=""

for (( c=1; c<=$top; c++ ))
do  
   relative_path="../""${relative_path}"
done

# Checking for valid az session

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

curdir=$(pwd)

echo ""
echo "#########################################################################################"
echo "#                                                                                       #" 
echo "#                           Bootstrapping the deployer                                  #"
echo "#                                                                                       #" 
echo "#########################################################################################"
echo ""

cd "${deployer_dirname}"
"${DEPLOYMENT_REPO_PATH}"deploy/scripts/install_deployer.sh -p $deployer_file_parametername -i true
if [ $? -eq 255 ]
   then
   exit $?
fi 
cd "${curdir}"

read -p "Do you want to specify the SPN Details Y/N?"  ans
answer=${ans^^}
if [ $answer == 'Y' ]; then
echo $library_config_information
    temp=$(grep "keyvault=" $library_config_information)
    if [ ! -z $temp ]
    then
        # Key vault was specified in ~/.sap_deployment_automation in the deployer file
        keyvault_name=$(echo $temp | cut -d= -f2 | xargs)
        keyvault_param=$(printf " -v %s " "{$keyvault_name}")
    fi    
    
    env_param=$(printf " -e %s " "${environment}")
    region_param=$(printf " -r %s " "${region}")
    
    allParams=${env_param}${keyvault_param}${region_param}

    echo $allParams
    exit 255

    "${DEPLOYMENT_REPO_PATH}"deploy/scripts/set_secrets.sh $allParams 
    if [ $? -eq 255 ]
        then
        exit $?
    fi 
fi

echo ""
echo "#########################################################################################"
echo "#                                                                                       #" 
echo "#                           Bootstrapping the library                                   #"
echo "#                                                                                       #" 
echo "#########################################################################################"
echo ""

cd "${library_dirname}"
"${DEPLOYMENT_REPO_PATH}"deploy/scripts/install_library.sh -p $library_file_parametername -i true -d $relative_path$deployer_dirname
if [ $? -eq 255 ]
    then
    exit $?
fi 
cd "${curdir}"

echo ""
echo "#########################################################################################"
echo "#                                                                                       #" 
echo "#                           Migrating the deployer state                                #"
echo "#                                                                                       #" 
echo "#########################################################################################"
echo ""

cd "${deployer_dirname}"

# Remove the script file
if [ -f post_deployment.sh ]
then
    rm post_deployment.sh
fi
"${DEPLOYMENT_REPO_PATH}"deploy/scripts/installer.sh -p $deployer_file_parametername -i true -t sap_deployer
if [ $? -eq 255 ]
    then
    exit $?
fi 
cd "${curdir}"

echo ""

echo "#########################################################################################"
echo "#                                                                                       #" 
echo "#                           Migrating the library state                                 #"
echo "#                                                                                       #" 
echo "#########################################################################################"
echo ""

cd "${library_dirname}"
"${DEPLOYMENT_REPO_PATH}"deploy/scripts/installer.sh -p $library_file_parametername  -i true -t sap_library
if [ $? -eq 255 ]
    then
    exit $?
fi 
cd "${curdir}"
