#!/bin/bash
min() {
    printf "%s\n" "${@:2}" | sort "$1" | head -n1
}
max() {
    # using sort's -r (reverse) option - using tail instead of head is also possible
    min ${1}r ${@:2}
}

function showhelp {
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
    echo "#   [REPO-ROOT]deploy/scripts/validate.sh \                                             #"
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

# Read environment


environment=$(cat "${parameterfile}" | jq .infrastructure.environment | tr -d \")
region=$(cat "${parameterfile}" | jq .infrastructure.region | tr -d \")
echo "Deployment information"
echo "----------------------------------------------------------------------------"
echo "Environment:                 " $environment
echo "Region:                      " $region

if cat "${parameterfile}"  | jq --exit-status '.infrastructure.resource_group' >/dev/null; then
    if cat "${parameterfile}"  | jq --exit-status '.infrastructure.resource_group.arm_id' >/dev/null; then
        arm_id=$(cat "${parameterfile}" | jq .infrastructure.resource_group.arm_id | tr -d \")
        echo "Resource group:              " "${arm_id}"
    else
        if cat "${parameterfile}"  | jq --exit-status '.infrastructure.resource_group.name' >/dev/null; then
            name=$(cat "${parameterfile}" | jq .infrastructure.resource_group.name | tr -d \")
            echo "Resource group:              " "${name}"
        else
            echo "Resource group:              " "(name defined by automation)"
        fi
    fi
    
else
    echo "Resource group:              " "(name defined by automation)"
fi
###############################################################################
#                              SAP System                                     # 
###############################################################################
if [ "${deployment_system}" == sap_system ] ; then

    db_zone_count=$(cat "${parameterfile}" | jq ' .databases[0].zones | length')
    app_zone_count=$(cat "${parameterfile}" | jq ' .application.app_zones | length')
    scs_zone_count=$(cat "${parameterfile}" | jq ' .application.scs_zones | length')
    web_zone_count=$(cat "${parameterfile}" | jq ' .application.web_zones | length')

    ppg_count=$(max -g $db_zone_count $app_zone_count $scs_zone_count $web_zone_count)

    echo "PPG:                         " "($ppg_count) (name defined by automation)"
    echo ""
    echo "Networking"
    echo "----------------------------------------------------------------------------"
    
    if cat "${parameterfile}"  | jq --exit-status '.infrastructure.vnets.sap.name' >/dev/null; then
        name=$(cat "${parameterfile}" | jq .infrastructure.vnets.sap.name | tr -d \")
        echo "VNet Logical Name:         " "${name}"
    else
        echo "Error!!! The VNet logical name must be specified"
    fi
    
    if cat "${parameterfile}"  | jq --exit-status '.infrastructure.vnets.sap.subnet_admin' >/dev/null; then
        if cat "${parameterfile}"  | jq --exit-status '.infrastructure.vnets.sap.subnet_admin.arm_id' >/dev/null; then
            arm_id=$(cat "${parameterfile}" | jq .infrastructure.vnets.sap.subnet_admin.arm_id | tr -d \")
            echo "Admin subnet:           " "${arm_id}"
        else
            if cat "${parameterfile}"  | jq --exit-status '.infrastructure.vnets.sap.subnet_admin.name' >/dev/null; then
                name=$(cat "${parameterfile}" | jq .infrastructure.vnets.sap.subnet_admin.name | tr -d \")
                echo "Admin subnet:              " "${name}"
            else
                echo "Admin subnet:              " "(name defined by automation)"
            fi
            if cat "${parameterfile}"  | jq --exit-status '.infrastructure.vnets.sap.subnet_admin.prefix' >/dev/null; then
                prefix=$(cat "${parameterfile}" | jq .infrastructure.vnets.sap.subnet_admin.prefix | tr -d \")
                echo "Admin subnet prefix:       " "${prefix}"
            else
                echo "Error!!! The Admin subnet prefix must be specified"
            fi
        fi
        if cat "${parameterfile}"  | jq --exit-status '.infrastructure.vnets.sap.subnet_admin.nsg' >/dev/null; then
            if cat "${parameterfile}"  | jq --exit-status '.infrastructure.vnets.sap.subnet_admin.nsg.arm_id' >/dev/null; then
                arm_id=$(cat "${parameterfile}" | jq .infrastructure.vnets.sap.subnet_admin.nsg.arm_id | tr -d \")
                echo "Admin subnet nsg:       " "${arm_id}"
            else
                if cat "${parameterfile}"  | jq --exit-status '.infrastructure.vnets.sap.subnet_admin.nsg.name' >/dev/null; then
                    name=$(cat "${parameterfile}" | jq .infrastructure.vnets.sap.subnet_admin.nsg.name | tr -d \")
                    echo "Admin subnet nsg:          " "${name}"
                else
                    echo "Admin subnet nsg:          " "(name defined by automation)"
                fi
            fi
        else
            echo "Admin subnet nsg:          " "(name defined by automation)"
        fi
        
    else
        echo "Error!!! The Admin subnet must be specified"
    fi
    
    if cat "${parameterfile}"  | jq --exit-status '.infrastructure.vnets.sap.subnet_db' >/dev/null; then
        if cat "${parameterfile}"  | jq --exit-status '.infrastructure.vnets.sap.subnet_db.arm_id' >/dev/null; then
            arm_id=$(cat "${parameterfile}" | jq .infrastructure.vnets.sap.subnet_db.arm_id | tr -d \")
            echo "Database subnet:        " "${arm_id}"
        else
            if cat "${parameterfile}"  | jq --exit-status '.infrastructure.vnets.sap.subnet_db.name' >/dev/null; then
                name=$(cat "${parameterfile}" | jq .infrastructure.vnets.sap.subnet_db.name | tr -d \")
                echo "Database subnet:           " "${name}"
            else
                echo "Database subnet:           " "(name defined by automation)"
            fi
            if cat "${parameterfile}"  | jq --exit-status '.infrastructure.vnets.sap.subnet_db.prefix' >/dev/null; then
                prefix=$(cat "${parameterfile}" | jq .infrastructure.vnets.sap.subnet_db.prefix | tr -d \")
                echo "Database subnet prefix:    " "${prefix}"
            else
                echo "Error!!! The Database subnet prefix must be specified"
            fi
        fi
        
        if cat "${parameterfile}"  | jq --exit-status '.infrastructure.vnets.sap.subnet_db.nsg' >/dev/null; then
            if cat "${parameterfile}"  | jq --exit-status '.infrastructure.vnets.sap.subnet_db.nsg.arm_id' >/dev/null; then
                arm_id=$(cat "${parameterfile}" | jq .infrastructure.vnets.sap.subnet_db.nsg.arm_id | tr -d \")
                echo "Database subnet nsg:    " "${arm_id}"
            else
                if cat "${parameterfile}"  | jq --exit-status '.infrastructure.vnets.sap.subnet_db.nsg.name' >/dev/null; then
                    name=$(cat "${parameterfile}" | jq .infrastructure.vnets.sap.subnet_db.nsg.name | tr -d \")
                    echo "Database subnet nsg:       " "${name}"
                else
                    echo "Database subnet nsg:       " "(name defined by automation)"
                fi
            fi
        else
            echo "Database subnet nsg:       " "(name defined by automation)"
        fi
        
    else
        echo "Error!!! The Database subnet must be specified"
    fi
    
    if cat "${parameterfile}"  | jq --exit-status '.infrastructure.vnets.sap.subnet_app' >/dev/null; then
        if cat "${parameterfile}"  | jq --exit-status '.infrastructure.vnets.sap.subnet_app.arm_id' >/dev/null; then
            arm_id=$(cat "${parameterfile}" | jq .infrastructure.vnets.sap.subnet_app.arm_id | tr -d \")
            echo "Application subnet:     " "${arm_id}"
        else
            if cat "${parameterfile}"  | jq --exit-status '.infrastructure.vnets.sap.subnet_app.name' >/dev/null; then
                name=$(cat "${parameterfile}" | jq .infrastructure.vnets.sap.subnet_app.name | tr -d \")
                echo "Application subnet:        " "${name}"
            else
                echo "Application subnet:        " "(name defined by automation)"
            fi
            if cat "${parameterfile}"  | jq --exit-status '.infrastructure.vnets.sap.subnet_app.prefix' >/dev/null; then
                prefix=$(cat "${parameterfile}" | jq .infrastructure.vnets.sap.subnet_app.prefix | tr -d \")
                echo "Application subnet prefix: " "${prefix}"
            else
                echo "Error!!! The Application subnet prefix must be specified"
            fi
        fi
        
        if cat "${parameterfile}"  | jq --exit-status '.infrastructure.vnets.sap.subnet_app.nsg' >/dev/null; then
            if cat "${parameterfile}"  | jq --exit-status '.infrastructure.vnets.sap.subnet_app.nsg.arm_id' >/dev/null; then
                arm_id=$(cat "${parameterfile}" | jq .infrastructure.vnets.sap.subnet_app.nsg.arm_id | tr -d \")
                echo "Application subnet nsg: " "${arm_id}"
            else
                if cat "${parameterfile}"  | jq --exit-status '.infrastructure.vnets.sap.subnet_app.nsg.name' >/dev/null; then
                    name=$(cat "${parameterfile}" | jq .infrastructure.vnets.sap.subnet_app.nsg.name | tr -d \")
                    echo "Application subnet nsg:    " "${name}"
                else
                    echo "Application subnet nsg:    " "(name defined by automation)"
                fi
            fi
        else
            echo "Application subnet nsg:    " "(name defined by automation)"
        fi
        
    else
        echo "Error!!! The Application subnet must be specified"
    fi
    
    if cat "${parameterfile}"  | jq --exit-status '.infrastructure.vnets.sap.subnet_web' >/dev/null; then
        if cat "${parameterfile}"  | jq --exit-status '.infrastructure.vnets.sap.subnet_web.arm_id' >/dev/null; then
            arm_id=$(cat "${parameterfile}" | jq .infrastructure.vnets.sap.subnet_web.arm_id | tr -d \")
            echo "Web subnet:             " "${arm_id}"
        else
            if cat "${parameterfile}"  | jq --exit-status '.infrastructure.vnets.sap.subnet_web.name' >/dev/null; then
                name=$(cat "${parameterfile}" | jq .infrastructure.vnets.sap.subnet_web.name | tr -d \")
                echo "Web subnet:                " "${name}"
            else
                echo "Web subnet:                " "(name defined by automation)"
            fi
            if cat "${parameterfile}"  | jq --exit-status '.infrastructure.vnets.sap.subnet_web.prefix' >/dev/null; then
                prefix=$(cat "${parameterfile}" | jq .infrastructure.vnets.sap.subnet_web.prefix | tr -d \")
                echo "Web subnet prefix:         " "${prefix}"
            else
                echo "Error!!! The Web prefix must be specified"
            fi
        fi
        
        if cat "${parameterfile}"  | jq --exit-status '.infrastructure.vnets.sap.subnet_web.nsg' >/dev/null; then
            if cat "${parameterfile}"  | jq --exit-status '.infrastructure.vnets.sap.subnet_web.nsg.arm_id' >/dev/null; then
                arm_id=$(cat "${parameterfile}" | jq .infrastructure.vnets.sap.subnet_web.nsg.arm_id | tr -d \")
                echo "Web subnet nsg: " "${arm_id}"
            else
                if cat "${parameterfile}"  | jq --exit-status '.infrastructure.vnets.sap.subnet_web.nsg.name' >/dev/null; then
                    name=$(cat "${parameterfile}" | jq .infrastructure.vnets.sap.subnet_web.nsg.name | tr -d \")
                    echo "Web subnet nsg:            " "${name}"
                else
                    echo "Web subnet nsg:            " "(name defined by automation)"
                fi
            fi
        else
            echo "Web subnet nsg:            " "(name defined by automation)"
        fi
    fi
    
    echo ""
    
    echo "Database tier"
    echo "----------------------------------------------------------------------------"
    platform=$(cat "${parameterfile}" | jq .databases[0].platform | tr -d \")
    echo "Platform:                    " "${platform}"
    ha=$(cat "${parameterfile}" | jq .databases[0].high_availability )
    echo "High availability:           " "${ha}"
    nr=$(cat "${parameterfile}" | jq '.databases[0].dbnodes | length' )
    echo "Number of servers:           " "${nr}"
    size=$(cat "${parameterfile}" | jq .databases[0].size | tr -d \")
    echo "Database sizing:             " "${size}"
    echo "Database load balancer:      "  "(name defined by automation)"
    if [ $db_zone_count -gt 1 ] ; then
        echo "Database availability set:   "  "($db_zone_count) (name defined by automation)"
    else
        echo "Database availability set:   "  "(name defined by automation)"
    fi
    if cat "${parameterfile}"  | jq --exit-status '.databases[0].os.source_image_id' >/dev/null; then
        image=$(cat "${parameterfile}" | jq .databases[0].os.source_image_id | tr -d \")
        echo "Database os custom image:    " "${image}"
        if cat "${parameterfile}"  | jq --exit-status '.databases[0].os.os_type' >/dev/null; then
            os_type=$(cat "${parameterfile}" | jq .databases[0].os.os_type | tr -d \")
            echo "Database os type:            " "${os_type}"
        else
            echo "Error!!! Database os_type must be specified when using custom image"
        fi
    else
        publisher=$(cat "${parameterfile}" | jq .databases[0].os.publisher | tr -d \")
        echo "Image publisher:             " "${publisher}"
        offer=$(cat "${parameterfile}" | jq .databases[0].os.offer | tr -d \")
        echo "Image offer:                 " "${offer}"
        sku=$(cat "${parameterfile}" | jq .databases[0].os.sku | tr -d \")
        echo "Image sku:                   " "${sku}"
        version=$(cat "${parameterfile}" | jq .databases[0].os.version | tr -d \")
        echo "Image version:               " "${version}"
    fi
    
    if cat "${parameterfile}"  | jq --exit-status '.databases[0].zones' >/dev/null; then
        echo "Deployment:                  " "Zonal"
        zones=$(cat "${parameterfile}" | jq --compact-output .databases[0].zones)
        echo "  Zones:                     " "${zones}"
    else
        echo "Deployment:                  " "Regional"
    fi
    if cat "${parameterfile}"  | jq --exit-status '.databases[0].use_DHCP' >/dev/null; then
        use_DHCP=$(cat "${parameterfile}" | jq .databases[0].use_DHCP | tr -d \")
        if [ "true" == "${use_DHCP}" ]; then
            echo "Networking:                  " "Use Azure provided IP addresses"
        else
            echo "Networking:                  " "Use Customer provided IP addresses"
        fi
    else
        echo "Networking:                  " "Use Customer provided IP addresses"
    fi
    if cat "${parameterfile}"  | jq --exit-status '.databases[0].authentication.type' >/dev/null; then
        authentication=$(cat "${parameterfile}" | jq '.databases[0].authentication.type'  | tr -d \")
        echo "Authentication:              " "${authentication}"
    else
        echo "Authentication:              " "key"
    fi
    
    echo
    
    echo "Application tier"
    echo "----------------------------------------------------------------------------"
    if cat "${parameterfile}"  | jq --exit-status '.application.authentication.type' >/dev/null; then
        authentication=$(cat "${parameterfile}" | jq '.application.authentication.type'  | tr -d \")
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
    app_server_count=$(cat "${parameterfile}" | jq .application.application_server_count)
    echo "  Number of servers:         " "${app_server_count}"
    if cat "${parameterfile}"  | jq --exit-status '.application.os.source_image_id' >/dev/null; then
        image=$(cat "${parameterfile}" | jq .application.os.source_image_id | tr -d \")
        echo "  Custom image:          " "${image}"
        if cat "${parameterfile}"  | jq --exit-status '.application.os.os_type' >/dev/null; then
            os_type=$(cat "${parameterfile}" | jq .application.os.os_type | tr -d \")
            echo "  Image os type:     " "${os_type}"
        else
            echo "Error!!! Application os_type must be specified when using custom image"
        fi
    else
        publisher=$(cat "${parameterfile}" | jq .application.os.publisher | tr -d \")
        echo "  Image publisher:           " "${publisher}"
        offer=$(cat "${parameterfile}" | jq .application.os.offer | tr -d \")
        echo "  Image offer:               " "${offer}"
        sku=$(cat "${parameterfile}" | jq .application.os.sku | tr -d \")
        echo "  Image sku:                 " "${sku}"
        version=$(cat "${parameterfile}" | jq .application.os.version | tr -d \")
        echo "  Image version:             " "${version}"
    fi
    if cat "${parameterfile}"  | jq --exit-status '.application.app_zones' >/dev/null; then
        echo "  Deployment:                " "Zonal"
        zones=$(cat "${parameterfile}" | jq --compact-output .application.app_zones)
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
    scs_server_count=$(cat "${parameterfile}" | jq .application.scs_server_count)
    echo "  Number of servers:         " "${scs_server_count}"
    scs_server_ha=$(cat "${parameterfile}" | jq .application.scs_high_availability)
    echo "  High availability:         " "${scs_server_ha}"

    if cat "${parameterfile}"  | jq --exit-status '.application.scs_os' >/dev/null; then
        if cat "${parameterfile}"  | jq --exit-status '.application.scs_os.source_image_id' >/dev/null; then
            image=$(cat "${parameterfile}" | jq .application.scs_os.source_image_id | tr -d \")
            echo "  Custom image:          " "${image}"
            if cat "${parameterfile}"  | jq --exit-status '.application.scs_os.os_type' >/dev/null; then
                os_type=$(cat "${parameterfile}" | jq .application.scs_os.os_type | tr -d \")
                echo "  Image os type:     " "${os_type}"
            else
                echo "Error!!! SCS os_type must be specified when using custom image"
            fi
        else
            publisher=$(cat "${parameterfile}" | jq .application.scs_os.publisher | tr -d \")
            echo "  Image publisher:           " "${publisher}"
            offer=$(cat "${parameterfile}" | jq .application.scs_os.offer | tr -d \")
            echo "  Image offer:               " "${offer}"
            sku=$(cat "${parameterfile}" | jq .application.scs_os.sku | tr -d \")
            echo "  Image sku:                 " "${sku}"
            version=$(cat "${parameterfile}" | jq .application.scs_os.version | tr -d \")
            echo "  Image version:             " "${version}"
        fi
    else
        if cat "${parameterfile}"  | jq --exit-status '.application.os.source_image_id' >/dev/null; then
            image=$(cat "${parameterfile}" | jq .application.os.source_image_id | tr -d \")
            echo "  Custom image:          " "${image}"
            if cat "${parameterfile}"  | jq --exit-status '.application.os.os_type' >/dev/null; then
                os_type=$(cat "${parameterfile}" | jq .application.os.os_type | tr -d \")
                echo "  Image os type:     " "${os_type}"
            else
                echo "Error!!! Application os_type must be specified when using custom image"
            fi
        else
            publisher=$(cat "${parameterfile}" | jq .application.os.publisher | tr -d \")
            echo "  Image publisher:           " "${publisher}"
            offer=$(cat "${parameterfile}" | jq .application.os.offer | tr -d \")
            echo "  Image offer:               " "${offer}"
            sku=$(cat "${parameterfile}" | jq .application.os.sku | tr -d \")
            echo "  Image sku:                 " "${sku}"
            version=$(cat "${parameterfile}" | jq .application.os.version | tr -d \")
            echo "  Image version:             " "${version}"
        fi
    fi
    if cat "${parameterfile}"  | jq --exit-status '.application.scs_zones' >/dev/null; then
        echo "  Deployment:                " "Zonal"
        zones=$(cat "${parameterfile}" | jq --compact-output .application.scs_zones)
        echo "    Zones:                   " "${zones}"
    else
        echo "  Deployment:                " "Regional"
    fi
    
    echo "Web dispatcher"
    web_server_count=$(cat "${parameterfile}" | jq .application.webdispatcher_count)
    echo "  Web dispatcher lb:         " "(name defined by automation)"
    if [ $web_zone_count -gt 1 ] ; then
        echo "  Web dispatcher avset:      " "($web_zone_count) (name defined by automation)"
    else
        echo "  Web dispatcher avset:      " "(name defined by automation)"
    fi
    echo "  Number of servers:         " "${web_server_count}"
    
    if cat "${parameterfile}"  | jq --exit-status '.application.web_os' >/dev/null; then
        if cat "${parameterfile}"  | jq --exit-status '.application.web_os.source_image_id' >/dev/null; then
            image=$(cat "${parameterfile}" | jq .application.web_os.source_image_id | tr -d \")
            echo "  Custom image:          " "${image}"
            if cat "${parameterfile}"  | jq --exit-status '.application.web_os.os_type' >/dev/null; then
                os_type=$(cat "${parameterfile}" | jq .application.web_os.os_type | tr -d \")
                echo "  Image os type:     " "${os_type}"
            else
                echo "Error!!! SCS os_type must be specified when using custom image"
            fi
        else
            publisher=$(cat "${parameterfile}" | jq .application.web_os.publisher | tr -d \")
            echo "  Image publisher:           " "${publisher}"
            offer=$(cat "${parameterfile}" | jq .application.web_os.offer | tr -d \")
            echo "  Image offer:               " "${offer}"
            sku=$(cat "${parameterfile}" | jq .application.web_os.sku | tr -d \")
            echo "  Image sku:                 " "${sku}"
            version=$(cat "${parameterfile}" | jq .application.web_os.version | tr -d \")
            echo "  Image version:             " "${version}"
        fi
    else
        if cat "${parameterfile}"  | jq --exit-status '.application.os.source_image_id' >/dev/null; then
            image=$(cat "${parameterfile}" | jq .application.os.source_image_id | tr -d \")
            echo "  Custom image:          " "${image}"
            if cat "${parameterfile}"  | jq --exit-status '.application.os.os_type' >/dev/null; then
                os_type=$(cat "${parameterfile}" | jq .application.os.os_type | tr -d \")
                echo "  Image os type:     " "${os_type}"
            else
                echo "Error!!! Application os_type must be specified when using custom image"
            fi
        else
            publisher=$(cat "${parameterfile}" | jq .application.os.publisher | tr -d \")
            echo "  Image publisher:           " "${publisher}"
            offer=$(cat "${parameterfile}" | jq .application.os.offer | tr -d \")
            echo "  Image offer:               " "${offer}"
            sku=$(cat "${parameterfile}" | jq .application.os.sku | tr -d \")
            echo "  Image sku:                 " "${sku}"
            version=$(cat "${parameterfile}" | jq .application.os.version | tr -d \")
            echo "  Image version:             " "${version}"
        fi
    fi
    if cat "${parameterfile}"  | jq --exit-status '.application.scs_zones' >/dev/null; then
        echo "  Deployment:                " "Zonal"
        zones=$(cat "${parameterfile}" | jq --compact-output .application.scs_zones)
        echo "    Zones:                   " "${zones}"
    else
        echo "  Deployment:                " "Regional"
    fi
    
    echo ""
    echo "Key Vault"
    echo "----------------------------------------------------------------------------"
    if cat "${parameterfile}"  | jq --exit-status '.key_vault.kv_spn_id' >/dev/null; then
        kv=$(cat "${parameterfile}" | jq .key_vault.kv_spn_id | tr -d \")
        echo "  SPN Key Vault:             " "${kv}"
    else
        echo "  SPN Key Vault:             " "Deployer keyvault"
    fi
    
    if cat "${parameterfile}"  | jq --exit-status '.key_vault.kv_user_id' >/dev/null; then
        kv=$(cat "${parameterfile}" | jq .key_vault.kv_user_id | tr -d \")
        echo "  User Key Vault:            " "${kv}"
    else
        echo "  User Key Vault:            " "Workload keyvault"
    fi
    
    if cat "${parameterfile}"  | jq --exit-status '.key_vault.kv_prvt_id' >/dev/null; then
        kv=$(cat "${parameterfile}" | jq .key_vault.kv_prvt_id | tr -d \")
        echo "  Automation Key Vault:      " "${kv}"
    else
        echo "  Automation Key Vault:      " "Workload keyvault"
    fi
    
fi

###############################################################################
#                              SAP LAndscape                                  # 
###############################################################################

if [ "${deployment_system}" == sap_landscape ] ; then
    echo "Networking"
    echo "----------------------------------------------------------------------------"
    
    if cat "${parameterfile}"  | jq --exit-status '.infrastructure.vnets.sap.name' >/dev/null; then
        name=$(cat "${parameterfile}" | jq .infrastructure.vnets.sap.name | tr -d \")
        echo "VNet Logical Name:           " "${name}"
    else
        echo "Error!!! The VNet logical name must be specified"
    fi
    
    if cat "${parameterfile}"  | jq --exit-status '.infrastructure.vnets.sap' >/dev/null; then
        if cat "${parameterfile}"  | jq --exit-status '.infrastructure.vnets.sap.arm_id' >/dev/null; then
            arm_id=$(cat "${parameterfile}" | jq .infrastructure.vnets.sap.arm_id | tr -d \")
            echo "Virtual network:        " "${arm_id}"
        else
            if cat "${parameterfile}"  | jq --exit-status '.infrastructure.vnets.sap.name' >/dev/null; then
                name=$(cat "${parameterfile}" | jq .infrastructure.vnets.sap.name | tr -d \")
                echo "VNet Logical name:         " "${name}"
            fi
        fi
        if cat "${parameterfile}"  | jq --exit-status '.infrastructure.vnets.sap.address_space' >/dev/null; then
            prefix=$(cat "${parameterfile}" | jq .infrastructure.vnets.sap.address_space | tr -d \")
            echo "Address space:             " "${prefix}"
        else
            echo "Error!!! The Virtual network address space must be specified"
        fi
    else
        echo "Error!!! The Virtual network must be defined"
    fi
    
    echo ""
    echo "Key Vault"
    echo "----------------------------------------------------------------------------"
    if cat "${parameterfile}"  | jq --exit-status '.key_vault.kv_spn_id' >/dev/null; then
        kv=$(cat "${parameterfile}" | jq .key_vault.kv_spn_id | tr -d \")
        echo "  SPN Key Vault:             " "${kv}"
    else
        echo "  SPN Key Vault:             " "Deployer keyvault"
    fi
    
    if cat "${parameterfile}"  | jq --exit-status '.key_vault.kv_user_id' >/dev/null; then
        kv=$(cat "${parameterfile}" | jq .key_vault.kv_user_id | tr -d \")
        echo "  User Key Vault:            " "${kv}"
    else
        echo "  User Key Vault:            " "Workload keyvault"
    fi
    
    if cat "${parameterfile}"  | jq --exit-status '.key_vault.kv_prvt_id' >/dev/null; then
        kv=$(cat "${parameterfile}" | jq .key_vault.kv_prvt_id | tr -d \")
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
    echo "Key Vault"
    echo "----------------------------------------------------------------------------"
    if cat "${parameterfile}"  | jq --exit-status '.key_vault.kv_spn_id' >/dev/null; then
        kv=$(cat "${parameterfile}" | jq .key_vault.kv_spn_id | tr -d \")
        echo "  SPN Key Vault:             " "${kv}"
    else
        echo "  SPN Key Vault:             " "Deployer keyvault"
    fi
    
    if cat "${parameterfile}"  | jq --exit-status '.key_vault.kv_user_id' >/dev/null; then
        kv=$(cat "${parameterfile}" | jq .key_vault.kv_user_id | tr -d \")
        echo "  User Key Vault:            " "${kv}"
    else
        echo "  User Key Vault:            " "Library keyvault"
    fi
    
    if cat "${parameterfile}"  | jq --exit-status '.key_vault.kv_prvt_id' >/dev/null; then
        kv=$(cat "${parameterfile}" | jq .key_vault.kv_prvt_id | tr -d \")
        echo "  Automation Key Vault:      " "${kv}"
    else
        echo "  Automation Key Vault:      " "Library keyvault"
    fi
    
fi

###############################################################################
#                              SAP Deployer                                   # 
###############################################################################


if [ "${deployment_system}" == sap_deployer ] ; then
    if cat "${parameterfile}"  | jq --exit-status '.infrastructure.vnets.management' >/dev/null; then
        if cat "${parameterfile}"  | jq --exit-status '.infrastructure.vnets.management.arm_id' >/dev/null; then
            arm_id=$(cat "${parameterfile}" | jq .infrastructure.vnets.management.arm_id | tr -d \")
            echo "Virtual network:        " "${arm_id}"
        else
            if cat "${parameterfile}"  | jq --exit-status '.infrastructure.vnets.management.name' >/dev/null; then
                name=$(cat "${parameterfile}" | jq .infrastructure.vnets.management.name | tr -d \")
                echo "VNet Logical name  :      " "${name}"
            fi
        fi
        if cat "${parameterfile}"  | jq --exit-status '.infrastructure.vnets.management.address_space' >/dev/null; then
            prefix=$(cat "${parameterfile}" | jq .infrastructure.vnets.management.address_space | tr -d \")
            echo "Address space:                " "${prefix}"
        else
            echo "Error!!! The Virtual network address space must be specified"
        fi
    else
        echo "Error!!! The Virtual network must be defined"
    fi
    
    echo ""
    echo "Key Vault"
    echo "----------------------------------------------------------------------------"
    if cat "${parameterfile}"  | jq --exit-status '.key_vault.kv_spn_id' >/dev/null; then
        kv=$(cat "${parameterfile}" | jq .key_vault.kv_spn_id | tr -d \")
        echo "  SPN Key Vault:             " "${kv}"
    else
        echo "  SPN Key Vault:             " "Deployer keyvault"
    fi
    
    if cat "${parameterfile}"  | jq --exit-status '.key_vault.kv_user_id' >/dev/null; then
        kv=$(cat "${parameterfile}" | jq .key_vault.kv_user_id | tr -d \")
        echo "  User Key Vault:            " "${kv}"
    else
        echo "  User Key Vault:            " "Deployer keyvault"
    fi
    
    if cat "${parameterfile}"  | jq --exit-status '.key_vault.kv_prvt_id' >/dev/null; then
        kv=$(cat "${parameterfile}" | jq .key_vault.kv_prvt_id | tr -d \")
        echo "  Automation Key Vault:      " "${kv}"
    else
        echo "  Automation Key Vault:      " "Deployer keyvault"
    fi
fi
