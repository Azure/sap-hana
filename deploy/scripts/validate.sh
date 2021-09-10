#!/bin/bash

export PATH=/opt/terraform/bin:/opt/ansible/bin:${PATH}

exit_status=0

#colors for terminal
boldreduscore="\e[1;4;31m"
boldred="\e[1;31m"
cyan="\e[1;36m"
resetformatting="\e[0m"

min() {
    printf "%s\n" "${@:2}" | sort "$1" | head -n1
}
max() {
    # using sort's -r (reverse) option - using tail instead of head is also possible
    min ${1}r ${@:2}
}
error() {
    echo -e "${boldred}Error!!! ${@}${resetformatting}"
    exit_status=1
}
heading() {
    echo -e "${cyan}${@}${resetformatting}"
    echo "----------------------------------------------------------------------------"
}

showhelp() 
{
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#                                                                                       #"
    echo "#   This file contains the logic to validate parameters for the different systems       #"
    echo "#   The script experts the following exports:                                           #"
    echo "#                                                                                       #"
    echo "#     DEPLOYMENT_REPO_PATH the path to the folder containing the cloned sap-hana        #"
    echo "#                                                                                       #"
    echo "#                                                                                       #"
    echo "#   Usage: validate.sh                                                                  #"
    echo "#    -p or --parameterfile                        parameter file                        #"
    echo "#    -t or --type                                 type of system to deploy              #"
    echo "#                                                 valid options:                        #"
    echo "#                                                   sap_deployer                        #"
    echo "#                                                   sap_library                         #"
    echo "#                                                   sap_landscape                       #"
    echo "#                                                   sap_system                          #"
    echo "#    -h or --help                                 Show help                             #"
    echo "#                                                                                       #"
    echo "#   Example:                                                                            #"
    echo "#                                                                                       #"
    echo "#   [REPO-ROOT]deploy/scripts/validate.sh \                                             #"
    echo "#      --parameterfile PROD-WEEU-DEP00-INFRASTRUCTURE.json \                            #"
    echo "#      --type sap_deployer                                                              #"
    echo "#                                                                                       #"
    echo "#########################################################################################"

    exit 2
}

missing () {
    printf -v val %-.40s "$option"
    echo ""
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#   Missing environment variables: ${option}!!!              #"
    echo "#                                                                                       #"
    echo "#   Please export the folloing variables:                                               #"
    echo "#      DEPLOYMENT_REPO_PATH (path to the repo folder (sap-hana))                        #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
}


INPUT_ARGUMENTS=$(getopt -n validate -o p:t:h --longoptions type:,parameterfile:,help -- "$@")
VALID_ARGUMENTS=$?

if [ "$VALID_ARGUMENTS" != "0" ]; then
  showhelp
fi

eval set -- "$INPUT_ARGUMENTS"
while :
do
  case "$1" in
    -p | --parameterfile)   parameterfile="$2"       ; shift 2 ;;
    -t | --type)            deployment_system="$2"   ; shift 2 ;;
    -h | --help)            showhelp                 ; shift ;;
    --) shift; break ;;
  esac
done


# Read environment

if [ ! -f "${parameterfile}" ]
then
    printf -v val %-35.35s "$parameterfile"
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                 ${boldred}  Parameter file does not exist: ${val} ${resetformatting} #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    exit
fi

# Read environment
environment=$(jq --raw-output .infrastructure.environment "${parameterfile}")
region=$(jq --raw-output .infrastructure.region "${parameterfile}")

rg_name=$(jq --raw-output .infrastructure.resource_group.name "${parameterfile}")
rg_arm_id=$(jq --raw-output .infrastructure.resource_group.arm_id "${parameterfile}")

if [ \( -n "${rg_arm_id}" \) -a \( "${rg_arm_id}" != "null" \) ]
then
    rg_name=$(echo $rg_arm_id | cut -d/ -f5 | xargs)
fi


heading "Deployment information"
echo "Environment:                 " "$environment"
echo "Region:                      " "$region"

if [ -n $rgname ]
then
    echo "Resource group:              " "${rg_name}"
else
    echo "Resource group:              " "(name defined by automation)"
fi

###############################################################################
#                              SAP System                                     # 
###############################################################################
if [ "${deployment_system}" == sap_system ] ; then

    db_zone_count=$(jq '.databases[0].zones  | length' "${parameterfile}")
    app_zone_count=$(jq '.application.app_zones | length' "${parameterfile}")
    scs_zone_count=$(jq '.application.scs_zones | length' "${parameterfile}")
    web_zone_count=$(jq '.application.web_zones | length' "${parameterfile}")

    ppg_count=$(max -g $db_zone_count $app_zone_count $scs_zone_count $web_zone_count)

    echo "PPG:                         " "($ppg_count) (name defined by automation)"
    echo ""

    heading "Networking"

    vnet_name=$(jq --raw-output .infrastructure.vnets.sap.name "${parameterfile}")
    vnet_arm_id=$(jq --raw-output .infrastructure.vnets.sap.arm_id "${parameterfile}")
    if [ \( -n "${vnet_arm_id}" \) -a \( "${vnet_arm_id}" != "null" \) ]
    then
        vnet_name=$(echo $vnet_arm_id | cut -d/ -f9 | xargs)
    fi

    if [ \( -n "${vnet_name}" \) -a \( "${vnet_name}" != "null" \) ]
    then
        echo "VNet Logical Name:           " "${vnet_name}"
    else
        error "The VNet logical name must be specified"
    fi

    # TODO(rtamalin): The admin, db, app and web subnet processing
    # sections below represent the same code pattern with just the
    # subnet identifier and output prefix string changing. As such
    # they can be converted into a parameterised function call.

    # Admin subnet 

    subnet_name=$(jq --raw-output .infrastructure.vnets.sap.subnet_admin.name "${parameterfile}")
    subnet_arm_id=$(jq --raw-output .infrastructure.vnets.sap.subnet_admin.arm_id "${parameterfile}")
    subnet_prefix=$(jq --raw-output .infrastructure.vnets.sap.subnet_admin.prefix "${parameterfile}")
    if [ \( -n "${subnet_arm_id}" \) -a \( "${subnet_arm_id}" != "null" \) ]
    then
        subnet_name=$(echo $subnet_arm_id | cut -d/ -f11 | xargs)
    fi
    

    subnet_nsg_name=$(jq --raw-output .infrastructure.vnets.sap.subnet_admin.nsg.name "${parameterfile}")
    subnet_nsg_arm_id=$(jq --raw-output .infrastructure.vnets.sap.subnet_admin.nsg.arm_id "${parameterfile}")
    if [ \( -n "${subnet_nsg_arm_id}" \) -a \( "${subnet_nsg_arm_id}" != "null" \) ]
    then
        subnet_nsg_name=$(echo $subnet_nsg_arm_id | cut -d/ -f13)
    fi

    if [ \( -n "${subnet_name}" \) -a \( "${subnet_name}" != "null" \) ]
    then
        echo "Admin subnet:                " "${subnet_name}"
    else
        echo "Admin subnet:                " "Subnet defined by the workload/automation"
    fi

    if [ \( -n "${subnet_prefix}" \) -a \( "${subnet_prefix}" != "null" \) ]
    then
        echo "Admin subnet prefix:         " "${subnet_prefix}"
    else
        echo "Admin subnet prefix:         " "Subnet prefix defined by the workload/automation"
    fi

    if [ \( -n "${subnet_nsg_name}" \) -a \( "${subnet_nsg_name}" != "null" \) ]
    then
        echo "Admin nsg:                   " "${subnet_nsg_name}"
    else
        echo "Admin nsg:                   " "Defined by the workload/automation"
    fi
    
    # db subnet 
    
    subnet_name=$(jq --raw-output .infrastructure.vnets.sap.subnet_db.name "${parameterfile}")
    subnet_arm_id=$(jq --raw-output .infrastructure.vnets.sap.subnet_db.arm_id "${parameterfile}")
    subnet_prefix=$(jq --raw-output .infrastructure.vnets.sap.subnet_db.prefix "${parameterfile}")
    if [ \( -n "${subnet_arm_id}" \) -a \( "${subnet_arm_id}" != "null" \) ]
    then
        subnet_name=$(echo $subnet_arm_id | cut -d/ -f11 | xargs)
    fi
    

    subnet_nsg_name=$(jq --raw-output .infrastructure.vnets.sap.subnet_db.nsg.name "${parameterfile}")
    subnet_nsg_arm_id=$(jq --raw-output .infrastructure.vnets.sap.subnet_db.nsg.arm_id "${parameterfile}")
    if [ \( -n "${subnet_nsg_arm_id}" \) -a \( "${subnet_nsg_arm_id}" != "null" \) ]
    then
        subnet_nsg_name=$(echo $subnet_nsg_arm_id | cut -d/ -f13 | xargs)
    fi

    if [ \( -n "${subnet_name}" \) -a \( "${subnet_name}" != "null" \) ]
    then
        echo "db subnet:                   " "${subnet_name}"
    else
        echo "db subnet:                   " "Subnet defined by the workload/automation"
    fi

    if [ \( -n "${subnet_prefix}" \) -a \( "${subnet_prefix}" != "null" \) ]
    then
        echo "db subnet prefix:            " "${subnet_prefix}"
    else
        echo "db subnet prefix:            " "Subnet prefix defined by the workload/automation"
    fi

    if [ \( -n "${subnet_nsg_name}" \) -a \( "${subnet_nsg_name}" != "null" \) ]
    then
        echo "db nsg:                      " "${subnet_nsg_name}"
    else
        echo "db nsg:                      " "Defined by the workload/automation"
    fi
    
    # app subnet 
    
    subnet_name=$(jq --raw-output .infrastructure.vnets.sap.subnet_app.name "${parameterfile}")
    subnet_arm_id=$(jq --raw-output .infrastructure.vnets.sap.subnet_app.arm_id "${parameterfile}")
    subnet_prefix=$(jq --raw-output .infrastructure.vnets.sap.subnet_app.prefix "${parameterfile}")
    if [ \( -n "${subnet_arm_id}" \) -a \( "${subnet_arm_id}" != "null" \) ]
    then
        subnet_name=$(echo $subnet_arm_id | cut -d/ -f11 | xargs)
    fi

    subnet_nsg_name=$(jq --raw-output .infrastructure.vnets.sap.subnet_app.nsg.name "${parameterfile}")
    subnet_nsg_arm_id=$(jq --raw-output .infrastructure.vnets.sap.subnet_app.nsg.arm_id "${parameterfile}")
    if [ \( -n "${subnet_nsg_arm_id}" \) -a \( "${subnet_nsg_arm_id}" != "null" \) ]
    then
        subnet_nsg_name=$(echo $subnet_nsg_arm_id | cut -d/ -f13 | xargs)
    fi

    if [ \( -n "${subnet_name}" \) -a \( "${subnet_name}" != "null" \) ]
    then
        echo "app subnet:                  " "${subnet_name}"
    else 
        echo "app subnet:                  " "Subnet defined by the workload/automation"
    fi

    if [ \( -n "${subnet_prefix}" \) -a \( "${subnet_prefix}" != "null" \) ]
    then
        echo "app subnet prefix:           " "${subnet_prefix}"
    else
        echo "app subnet prefix:           " "Subnet prefix defined by the workload/automation"
    fi

    if [ \( -n "${subnet_nsg_name}" \) -a \( "${subnet_nsg_name}" != "null" \) ]
    then
        echo "app nsg:                     " "${subnet_nsg_name}"
    else
        echo "app nsg:                     " "Defined by the workload/automation"
    fi
    
    # web subnet 
    
    subnet_name=$(jq --raw-output .infrastructure.vnets.sap.subnet_web.name "${parameterfile}")
    subnet_arm_id=$(jq --raw-output .infrastructure.vnets.sap.subnet_web.arm_id "${parameterfile}")
    subnet_prefix=$(jq --raw-output .infrastructure.vnets.sap.subnet_web.prefix "${parameterfile}")
    if [ \( -n "${subnet_arm_id}" \) -a \( "${subnet_arm_id}" != "null" \) ]
    then
        subnet_name=$(echo $subnet_arm_id | cut -d/ -f11 | xargs)
    fi

    subnet_nsg_name=$(jq --raw-output .infrastructure.vnets.sap.subnet_web.nsg.name "${parameterfile}")
    subnet_nsg_arm_id=$(jq --raw-output .infrastructure.vnets.sap.subnet_web.nsg.arm_id "${parameterfile}")
    if [ \( -n "${subnet_nsg_arm_id}" \) -a \( "${subnet_nsg_arm_id}" != "null" \) ]
    then
        subnet_nsg_name=$(echo $subnet_nsg_arm_id | cut -d/ -f13 | xargs)
    fi

    if [ \( -n "${subnet_name}" \) -a \( "${subnet_name}" != "null" \) ]
    then
        echo "web subnet:                  " "${subnet_name}"
    else
        echo "web subnet:                  " "Subnet defined by the workload/automation"
    fi

    if [ \( -n "${subnet_prefix}" \) -a \( "${subnet_prefix}" != "null" \) ]
    then
        echo "web subnet prefix:           " "${subnet_prefix}"
    else
        echo "web subnet prefix:           " "Subnet prefix defined by the workload/automation"
    fi

    if [ \( -n "${subnet_nsg_name}" \) -a \( "${subnet_nsg_name}" != "null" \) ]
    then
        echo "web nsg:                     " "${subnet_nsg_name}"
    else
        echo "web nsg:                     " "Defined by the workload/automation"
    fi
    
    echo ""
    
    heading "Database tier"
    platform=$(jq --raw-output '.databases[0].platform' "${parameterfile}")
    echo "Platform:                    " "${platform}"
    ha=$(jq --raw-output '.databases[0].high_availability' "${parameterfile}")
    echo "High availability:           " "${ha}"
    nr=$(jq '.databases[0].dbnodes | length' "${parameterfile}")
    echo "Number of servers:           " "${nr}"
    size=$(jq --raw-output '.databases[0].size' "${parameterfile}")
    echo "Database sizing:             " "${size}"
    echo "Database load balancer:      "  "(name defined by automation)"
    if [ $db_zone_count -gt 1 ] ; then
        echo "Database availability set:   "  "($db_zone_count) (name defined by automation)"
    else
        echo "Database availability set:   "  "(name defined by automation)"
    fi
    if jq --exit-status '.databases[0].os.source_image_id' "${parameterfile}" >/dev/null; then
        image=$(jq --raw-output '.databases[0].os.source_image_id' "${parameterfile}")
        echo "Database os custom image:    " "${image}"
        if jq --exit-status '.databases[0].os.os_type' "${parameterfile}" >/dev/null; then
            os_type=$(jq --raw-output '.databases[0].os.os_type' "${parameterfile}")
            echo "Database os type:            " "${os_type}"
        else
            error "Database os_type must be specified when using custom image"
        fi
    else
        publisher=$(jq --raw-output '.databases[0].os.publisher' "${parameterfile}")
        echo "Image publisher:             " "${publisher}"
        offer=$(jq --raw-output '.databases[0].os.offer' "${parameterfile}")
        echo "Image offer:                 " "${offer}"
        sku=$(jq --raw-output '.databases[0].os.sku' "${parameterfile}")
        echo "Image sku:                   " "${sku}"
        version=$(jq --raw-output '.databases[0].os.version' "${parameterfile}")
        echo "Image version:               " "${version}"
    fi
    
    if jq --exit-status '.databases[0].zones' "${parameterfile}" >/dev/null; then
        echo "Deployment:                  " "Zonal"
        zones=$(jq --compact-output '.databases[0].zones' "${parameterfile}")
        echo "  Zones:                     " "${zones}"
    else
        echo "Deployment:                  " "Regional"
    fi
    if jq --exit-status '.databases[0].use_DHCP' "${parameterfile}" >/dev/null; then
        use_DHCP=$(jq --raw-output '.databases[0].use_DHCP'  "${parameterfile}")
        if [ "true" == "${use_DHCP}" ]; then
            echo "Networking:                  " "Use Azure provided IP addresses"
        else
            echo "Networking:                  " "Use Customer provided IP addresses"
        fi
    else
        echo "Networking:                  " "Use Customer provided IP addresses"
    fi
    if jq --exit-status '.databases[0].authentication.type' "${parameterfile}" >/dev/null; then
        authentication=$(jq --raw-output '.databases[0].authentication.type' "${parameterfile}")
        echo "Authentication:              " "${authentication}"
    else
        echo "Authentication:              " "key"
    fi
    
    echo
    
    heading "Application tier"
    if jq --exit-status '.application.authentication.type' "${parameterfile}" >/dev/null; then
        authentication=$(jq --raw-output '.application.authentication.type' "${parameterfile}")
        echo "Authentication:              " "${authentication}"
    else
        echo "Authentication:              " "key"
    fi
    
    echo "Application servers"
    if [ $app_zone_count -gt 1 ] ; then
        echo "  Application avset:         " "($app_zone_count) (name defined by automation)"
    else
        echo "  Application avset:         " "(name defined by automation)"
    fi
    app_server_count=$(jq --raw-output .application.application_server_count "${parameterfile}")
    echo "  Number of servers:         " "${app_server_count}"
    if jq --exit-status '.application.os.source_image_id' "${parameterfile}" >/dev/null; then
        image=$(jq --raw-output .application.os.source_image_id "${parameterfile}")
        echo "  Custom image:          " "${image}"
        if jq --exit-status '.application.os.os_type' "${parameterfile}" >/dev/null; then
            os_type=$(jq --raw-output .application.os.os_type  "${parameterfile}")
            echo "  Image os type:     " "${os_type}"
        else
            error "Application os_type must be specified when using custom image"
        fi
    else
        publisher=$(jq --raw-output .application.os.publisher "${parameterfile}")
        echo "  Image publisher:           " "${publisher}"
        offer=$(jq --raw-output .application.os.offer "${parameterfile}")
        echo "  Image offer:               " "${offer}"
        sku=$(jq --raw-output .application.os.sku "${parameterfile}")
        echo "  Image sku:                 " "${sku}"
        version=$(jq --raw-output .application.os.version "${parameterfile}")
        echo "  Image version:             " "${version}"
    fi
    if jq --exit-status '.application.app_zones' "${parameterfile}" >/dev/null; then
        echo "  Deployment:                " "Zonal"
        zones=$(jq --compact-output .application.app_zones "${parameterfile}")
        echo "    Zones:                   " "${zones}"
    else
        echo "  Deployment:                " "Regional"
    fi
    
    echo "Central Services"
    echo "  SCS load balancer:         " "(name defined by automation)"
    if [ $scs_zone_count -gt 1 ] ; then
        echo "  SCS avset:                 " "($scs_zone_count) (name defined by automation)"
    else
        echo "  SCS avset:                 " "(name defined by automation)"
    fi
    scs_server_count=$(jq --raw-output .application.scs_server_count "${parameterfile}")
    echo "  Number of servers:         " "${scs_server_count}"
    scs_server_ha=$(jq --raw-output .application.scs_high_availability "${parameterfile}")
    echo "  High availability:         " "${scs_server_ha}"

    if jq --exit-status '.application.scs_os' "${parameterfile}" >/dev/null; then
        if jq --exit-status '.application.scs_os.source_image_id' "${parameterfile}" >/dev/null; then
            image=$(jq --raw-output .application.scs_os.source_image_id  "${parameterfile}")
            echo "  Custom image:          " "${image}"
            if jq --exit-status '.application.scs_os.os_type' "${parameterfile}" >/dev/null; then
                os_type=$(jq --raw-output .application.scs_os.os_type "${parameterfile}")
                echo "  Image os type:     " "${os_type}"
            else
                error "SCS os_type must be specified when using custom image"
            fi
        else
            publisher=$(jq --raw-output .application.scs_os.publisher "${parameterfile}")
            echo "  Image publisher:           " "${publisher}"
            offer=$(jq --raw-output .application.scs_os.offer "${parameterfile}")
            echo "  Image offer:               " "${offer}"
            sku=$(jq --raw-output .application.scs_os.sku "${parameterfile}")
            echo "  Image sku:                 " "${sku}"
            version=$(jq --raw-output .application.scs_os.version "${parameterfile}")
            echo "  Image version:             " "${version}"
        fi
    else
        if jq --exit-status '.application.os.source_image_id' "${parameterfile}" >/dev/null; then
            image=$(jq --raw-output .application.os.source_image_id "${parameterfile}")
            echo "  Custom image:          " "${image}"
            if jq --exit-status '.application.os.os_type' "${parameterfile}" >/dev/null; then
                os_type=$(jq --raw-output .application.os.os_type "${parameterfile}")
                echo "  Image os type:     " "${os_type}"
            else
                error "Application os_type must be specified when using custom image"
            fi
        else
            publisher=$(jq --raw-output .application.os.publisher "${parameterfile}")
            echo "  Image publisher:           " "${publisher}"
            offer=$(jq --raw-output .application.os.offer "${parameterfile}")
            echo "  Image offer:               " "${offer}"
            sku=$(jq --raw-output .application.os.sku "${parameterfile}")
            echo "  Image sku:                 " "${sku}"
            version=$(jq --raw-output .application.os.version "${parameterfile}")
            echo "  Image version:             " "${version}"
        fi
    fi
    if jq --exit-status '.application.scs_zones' "${parameterfile}" >/dev/null; then
        echo "  Deployment:                " "Zonal"
        zones=$(jq --compact-output .application.scs_zones "${parameterfile}")
        echo "    Zones:                   " "${zones}"
    else
        echo "  Deployment:                " "Regional"
    fi
    
    echo "Web dispatcher"
    web_server_count=$(jq --raw-output .application.webdispatcher_count "${parameterfile}")
    echo "  Web dispatcher lb:         " "(name defined by automation)"
    if [ $web_zone_count -gt 1 ] ; then
        echo "  Web dispatcher avset:      " "($web_zone_count) (name defined by automation)"
    else
        echo "  Web dispatcher avset:      " "(name defined by automation)"
    fi
    echo "  Number of servers:         " "${web_server_count}"
    
    if jq --exit-status '.application.web_os' "${parameterfile}" >/dev/null; then
        if jq --exit-status '.application.web_os.source_image_id' "${parameterfile}" >/dev/null; then
            image=$(jq --raw-output .application.web_os.source_image_id "${parameterfile}")
            echo "  Custom image:          " "${image}"
            if jq --exit-status '.application.web_os.os_type' "${parameterfile}" >/dev/null; then
                os_type=$(jq --raw-output .application.web_os.os_type "${parameterfile}")
                echo "  Image os type:     " "${os_type}"
            else
                error "SCS os_type must be specified when using custom image"
            fi
        else
            publisher=$(jq --raw-output .application.web_os.publisher "${parameterfile}")
            echo "  Image publisher:           " "${publisher}"
            offer=$(jq --raw-output .application.web_os.offer "${parameterfile}")
            echo "  Image offer:               " "${offer}"
            sku=$(jq --raw-output .application.web_os.sku "${parameterfile}")
            echo "  Image sku:                 " "${sku}"
            version=$(jq --raw-output .application.web_os.version "${parameterfile}")
            echo "  Image version:             " "${version}"
        fi
    else
        if jq --exit-status '.application.os.source_image_id' "${parameterfile}" >/dev/null; then
            image=$(jq --raw-output .application.os.source_image_id "${parameterfile}")
            echo "  Custom image:          " "${image}"
            if jq --exit-status '.application.os.os_type' "${parameterfile}" >/dev/null; then
                os_type=$(jq --raw-output .application.os.os_type "${parameterfile}")
                echo "  Image os type:     " "${os_type}"
            else
                error "Application os_type must be specified when using custom image"
            fi
        else
            publisher=$(jq --raw-output .application.os.publisher "${parameterfile}")
            echo "  Image publisher:           " "${publisher}"
            offer=$(jq --raw-output .application.os.offer "${parameterfile}")
            echo "  Image offer:               " "${offer}"
            sku=$(jq --raw-output .application.os.sku "${parameterfile}")
            echo "  Image sku:                 " "${sku}"
            version=$(jq --raw-output .application.os.version "${parameterfile}")
            echo "  Image version:             " "${version}"
        fi
    fi
    if jq --exit-status '.application.scs_zones' "${parameterfile}" >/dev/null; then
        echo "  Deployment:                " "Zonal"
        zones=$(jq --compact-output .application.scs_zones "${parameterfile}")
        echo "    Zones:                   " "${zones}"
    else
        echo "  Deployment:                " "Regional"
    fi
    
    echo ""
    heading "Key Vault"
    if jq --exit-status '.key_vault.kv_spn_id' "${parameterfile}" >/dev/null; then
        kv=$(jq --raw-output .key_vault.kv_spn_id "${parameterfile}")
        echo "  SPN Key Vault:             " "${kv}"
    else
        echo "  SPN Key Vault:             " "Deployer keyvault"
    fi
    
    if jq --exit-status '.key_vault.kv_user_id' "${parameterfile}" >/dev/null; then
        kv=$(jq --raw-output .key_vault.kv_user_id "${parameterfile}")
        echo "  User Key Vault:            " "${kv}"
    else
        echo "  User Key Vault:            " "Workload keyvault"
    fi
    
    if jq --exit-status '.key_vault.kv_prvt_id' "${parameterfile}" >/dev/null; then
        kv=$(jq --raw-output .key_vault.kv_prvt_id "${parameterfile}")
        echo "  Automation Key Vault:      " "${kv}"
    else
        echo "  Automation Key Vault:      " "Workload keyvault"
    fi
    
fi

###############################################################################
#                              SAP Landscape                                  # 
###############################################################################
if [ "${deployment_system}" == sap_landscape ] ; then
    heading "Networking"
    
    vnet_name=$(jq --raw-output .infrastructure.vnets.sap.name "${parameterfile}")
    vnet_arm_id=$(jq --raw-output .infrastructure.vnets.sap.arm_id "${parameterfile}")
    vnet_address_space=$(jq --raw-output .infrastructure.vnets.sap.address_space "${parameterfile}")
    if [ -z "${vnet_arm_id}" ]
    then
        vnet_name=$(echo $vnet_arm_id | cut -d/ -f19 | xargs)
    fi

    echo "VNet Logical name:           " "${vnet_name}"
    echo "Address space:               " "${vnet_address_space}"
    # Admin subnet 

    subnet_name=$(jq --raw-output .infrastructure.vnets.sap.subnet_admin.name "${parameterfile}")
    subnet_arm_id=$(jq --raw-output .infrastructure.vnets.sap.subnet_admin.arm_id "${parameterfile}")
    subnet_prefix=$(jq --raw-output .infrastructure.vnets.sap.subnet_admin.prefix "${parameterfile}")
    if [ -z "${subnet_arm_id}" ]
    then
        subnet_name=$(echo $subnet_arm_id | cut -d/ -f11 | xargs)
    fi

    subnet_nsg_name=$(jq --raw-output .infrastructure.vnets.sap.subnet_admin.nsg.name "${parameterfile}")
    subnet_nsg_arm_id=$(jq --raw-output .infrastructure.vnets.sap.subnet_admin.nsg.arm_id "${parameterfile}")
    if [ -z "${subnet_nsg_arm_id}" ]
    then
        subnet_nsg_name=$(echo $subnet_nsg_arm_id | cut -d/ -f13 | xargs)
    fi

    if [ -z "${subnet_name}" ]
    then
        echo "Admin subnet:                " "${subnet_name}"
    else
        echo "Admin subnet:                " "Subnet defined by the system/automation"
    fi
    if [ -z "${subnet_prefix}" ]
    then
        echo "Admin subnet prefix:         " "${subnet_name}"
    else
        echo "Admin subnet prefix:         " "Subnet prefix defined by the system/automation"
    fi
    if [ -z "${subnet_nsg_name}" ]
    then
        echo "Admin nsg:                   " "${subnet_nsg_name}"
    else
        echo "Admin nsg:                   " "Defined by the system/automation"
    fi
    
    # db subnet 
    
    subnet_name=$(jq --raw-output .infrastructure.vnets.sap.subnet_db.name "${parameterfile}")
    subnet_arm_id=$(jq --raw-output .infrastructure.vnets.sap.subnet_db.arm_id "${parameterfile}")
    subnet_prefix=$(jq --raw-output .infrastructure.vnets.sap.subnet_db.prefix "${parameterfile}")
    if [ -z "${subnet_arm_id}" ]
    then
        subnet_name=$(echo $subnet_arm_id | cut -d/ -f11 | xargs)
    fi
    
    subnet_nsg_name=$(jq --raw-output .infrastructure.vnets.sap.subnet_db.nsg.name "${parameterfile}")
    subnet_nsg_arm_id=$(jq --raw-output .infrastructure.vnets.sap.subnet_db.nsg.arm_id "${parameterfile}")
    if [ -z "${subnet_nsg_arm_id}" ]
    then
        subnet_nsg_name=$(echo $subnet_nsg_arm_id | cut -d/ -f13 | xargs)
    fi

    if [ -z "${subnet_name}" ]
    then
        echo "db subnet:                   " "${subnet_name}"
    else
        echo "db subnet:                   " "Subnet defined by the system/automation"
    fi
    if [ -z "${subnet_prefix}" ]
    then
        echo "db subnet prefix:            " "${subnet_name}"
    else
        echo "db subnet prefix:            " "Subnet prefix defined by the system/automation"
    fi
    if [ -z "${subnet_nsg_name}" ]
    then
        echo "db nsg:                      " "${subnet_nsg_name}"
    else
        echo "db nsg:                      " "Defined by the system/automation"
    fi
    
    # app subnet 
    
    subnet_name=$(jq --raw-output .infrastructure.vnets.sap.subnet_app.name "${parameterfile}")
    subnet_arm_id=$(jq --raw-output .infrastructure.vnets.sap.subnet_app.arm_id "${parameterfile}")
    subnet_prefix=$(jq --raw-output .infrastructure.vnets.sap.subnet_app.prefix "${parameterfile}")
    if [ -z "${subnet_arm_id}" ]
    then
        subnet_name=$(echo $subnet_arm_id | cut -d/ -f11 | xargs)
    fi

    subnet_nsg_name=$(jq --raw-output .infrastructure.vnets.sap.subnet_app.nsg.name "${parameterfile}")
    subnet_nsg_arm_id=$(jq --raw-output .infrastructure.vnets.sap.subnet_app.nsg.arm_id "${parameterfile}")
    if [ -z "${subnet_nsg_arm_id}" ]
    then
        subnet_nsg_name=$(echo $subnet_nsg_arm_id | cut -d/ -f13 | xargs)
    fi

    if [ -z "${subnet_name}" ]
    then
        echo "app subnet:                  " "${subnet_name}"
    else
        echo "app subnet:                  " "Subnet defined by the system/automation"
    fi
    if [ -z "${subnet_prefix}" ]
    then
        echo "app subnet prefix:           " "${subnet_name}"
    else
        echo "app subnet prefix:           " "Subnet prefix defined by the system/automation"
    fi
    if [ -z "${subnet_nsg_name}" ]
    then
        echo "app nsg:                     " "${subnet_nsg_name}"
    else
        echo "app nsg:                     " "Defined by the system/automation"
    fi
    
    # web subnet 
    
    subnet_name=$(jq --raw-output .infrastructure.vnets.sap.subnet_web.name "${parameterfile}")
    subnet_arm_id=$(jq --raw-output .infrastructure.vnets.sap.subnet_web.arm_id "${parameterfile}")
    subnet_prefix=$(jq --raw-output .infrastructure.vnets.sap.subnet_web.prefix "${parameterfile}")
    if [ -z "${subnet_arm_id}" ]
    then
        subnet_name=$(echo $subnet_arm_id | cut -d/ -f11 | xargs)
    fi

    subnet_nsg_name=$(jq --raw-output .infrastructure.vnets.sap.subnet_web.nsg.name "${parameterfile}")
    subnet_nsg_arm_id=$(jq --raw-output .infrastructure.vnets.sap.subnet_web.nsg.arm_id "${parameterfile}")
    if [ -z "${subnet_nsg_arm_id}" ]
    then
        subnet_nsg_name=$(echo $subnet_nsg_arm_id | cut -d/ -f13 | xargs)
    fi

    if [ -z "${subnet_name}" ]
    then
        echo "web subnet:                  " "${subnet_name}"
    else    
        echo "web subnet:                  " "Subnet defined by the system/automation"
    fi
    if [ -z "${subnet_prefix}" ]
    then
        echo "web subnet prefix:           " "${subnet_name}"
    else
        echo "web subnet prefix:           " "Subnet prefix defined by the system/automation"
    fi
    if [ -z "${subnet_nsg_name}" ]
    then
        echo "web nsg:                     " "${subnet_nsg_name}"
    else
        echo "web nsg:                     " "Defined by the system/automation"
    fi
    
    
    echo ""
    heading "Key Vault"
    if jq --exit-status '.key_vault.kv_spn_id' "${parameterfile}" >/dev/null; then
        kv=$(jq --raw-output .key_vault.kv_spn_id "${parameterfile}")
        echo "  SPN Key Vault:             " "${kv}"
    else
        echo "  SPN Key Vault:             " "Deployer keyvault"
    fi
    
    if jq --exit-status '.key_vault.kv_user_id' "${parameterfile}" >/dev/null; then
        kv=$(jq --raw-output .key_vault.kv_user_id "${parameterfile}")
        echo "  User Key Vault:            " "${kv}"
    else
        echo "  User Key Vault:            " "Workload keyvault"
    fi
    
    if jq --exit-status '.key_vault.kv_prvt_id' "${parameterfile}" >/dev/null; then
        kv=$(jq --raw-output .key_vault.kv_prvt_id "${parameterfile}")
        echo "  Automation Key Vault:      " "${kv}"
    else
        echo "  Automation Key Vault:      " "Workload keyvault"
    fi
fi

###############################################################################
#                              SAP Library                                    # 
###############################################################################

if [ "${deployment_system}" == sap_library ] ; then
    echo ""
    heading "Key Vault"
    if jq --exit-status '.key_vault.kv_spn_id' "${parameterfile}" >/dev/null; then
        kv=$(jq --raw-output .key_vault.kv_spn_id "${parameterfile}")
        echo "  SPN Key Vault:             " "${kv}"
    else
        echo "  SPN Key Vault:             " "Deployer keyvault"
    fi
    
    if jq --exit-status '.key_vault.kv_user_id' "${parameterfile}" >/dev/null; then
        kv=$(jq --raw-output .key_vault.kv_user_id "${parameterfile}")
        echo "  User Key Vault:            " "${kv}"
    else
        echo "  User Key Vault:            " "Library keyvault"
    fi
    
    if jq --exit-status '.key_vault.kv_prvt_id' "${parameterfile}" >/dev/null; then
        kv=$(jq --raw-output .key_vault.kv_prvt_id "${parameterfile}")
        echo "  Automation Key Vault:      " "${kv}"
    else
        echo "  Automation Key Vault:      " "Library keyvault"
    fi
    
fi

###############################################################################
#                              SAP Deployer                                   # 
###############################################################################

if [ "${deployment_system}" == sap_deployer ] ; then
    heading "Networking"    
    if jq --exit-status '.infrastructure.vnets.management' "${parameterfile}" >/dev/null; then
        if jq --exit-status '.infrastructure.vnets.management.arm_id' "${parameterfile}" >/dev/null; then
            arm_id=$(jq --raw-output .infrastructure.vnets.management.arm_id "${parameterfile}")
            echo "Virtual network:        " "${arm_id}"
        else
            if jq --exit-status '.infrastructure.vnets.management.name' "${parameterfile}" >/dev/null; then
                name=$(jq --raw-output .infrastructure.vnets.management.name "${parameterfile}")
                echo "VNet Logical name:           " "${name}"
            fi
        fi
        if jq --exit-status '.infrastructure.vnets.management.address_space' "${parameterfile}" >/dev/null; then
            prefix=$(jq --raw-output .infrastructure.vnets.management.address_space "${parameterfile}")
            echo "Address space:               " "${prefix}"
        else
            error "The Virtual network address space must be specified"
        fi
    else
        error "The Virtual network must be defined"
    fi
    
    echo ""
    heading "Key Vault"    
    if jq --exit-status '.key_vault.kv_spn_id' "${parameterfile}" >/dev/null; then
        kv=$(jq --raw-output .key_vault.kv_spn_id "${parameterfile}")
        echo "  SPN Key Vault:             " "${kv}"
    else
        echo "  SPN Key Vault:             " "Deployer keyvault"
    fi
    
    if jq --exit-status '.key_vault.kv_user_id' "${parameterfile}" >/dev/null; then
        kv=$(jq --raw-output .key_vault.kv_user_id "${parameterfile}")
        echo "  User Key Vault:            " "${kv}"
    else
        echo "  User Key Vault:            " "Deployer keyvault"
    fi
    
    if jq --exit-status '.key_vault.kv_prvt_id' "${parameterfile}" >/dev/null; then
        kv=$(jq --raw-output .key_vault.kv_prvt_id "${parameterfile}")
        echo "  Automation Key Vault:      " "${kv}"
    else
        echo "  Automation Key Vault:      " "Deployer keyvault"
    fi
fi

exit ${exit_status}
