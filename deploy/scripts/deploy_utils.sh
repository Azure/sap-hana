#!/bin/bash

#########################################################################
# Helper utilities
#
# Acknowledgements: Fergal Mc Carthy, SUSE
#########################################################################

function save_config_var() {
    local var_name=$1 var_file=$2
    sed -i -e "" -e /$var_name/d "${var_file}"
    echo "${var_name}=${!var_name}" >> "${var_file}"
}

function save_config_vars() {
    local var_file="${1}" var_name
       
    shift  # shift params 1 place to remove var_file value from front of list
    
    for var_name  # iterate over function params
    do
        sed -i -e "" -e /${var_name}/d "${var_file}"
        echo "${var_name}=${!var_name}" >> "${var_file}"
        
    done
}

function load_config_vars() {
    local var_file="${1}" 
    local var_name="${2}" 
    local var_value
    
    for var_name
    do
        if [ -f "${var_file}" ]
        then
            var_value="$(grep -m1 "^${var_name}=" "${var_file}" | cut -d'=' -f2 | tr -d '"')"
        fi
        
        [[ -z "${var_value}" ]] && continue #switch to compound command `[[` instead of `[`
        
        typeset -g "${var_name}"  # declare the specified variable as global
        
        eval "${var_name}='${var_value}'"  # set the variable in global context
    done
}


function init() {
    local automation_config_directory="${1}"
    local generic_config_information="${2}"
    local app_config_information="${3}"
    
    if [ ! -d "${automation_config_directory}" ]
    then
        # No configuration directory exists
        mkdir "${automation_config_directory}"
        touch "${app_config_information}"
        touch "${generic_config_information}"
        if [ -n "${DEPLOYMENT_REPO_PATH}" ]; then
            # Store repo path in ~/.sap_deployment_automation/config
            save_config_var "DEPLOYMENT_REPO_PATH" "${generic_config_information}"
        fi
        if [ -n "$ARM_SUBSCRIPTION_ID" ]; then
            # Store ARM Subscription info in ~/.sap_deployment_automation
            save_config_var "ARM_SUBSCRIPTION_ID" "${app_config_information}"
        fi
        
    else
        touch "${generic_config_information}"
        touch "${app_config_information}"
        load_config_vars "${generic_config_information}" "DEPLOYMENT_REPO_PATH"
        load_config_vars "${app_config_information}" "ARM_SUBSCRIPTION_ID"
    fi
    
    
}

function error_msg {
    echo "Error!!! ${@}"
}

function fail_if_null {
    local var_name="${1}"

    # return immeditaely if no action required
    if [ "${!var_name}" != "null" ]; then
        return
    fi

    shift 1

    if (( $# > 0 )); then
        error_msg "${@}"
    else
        error_msg "Got a null value for '${var_name}'"
    fi

    exit 1
}

function get_and_store_sa_details {
    local REMOTE_STATE_SA="${1}"
    local config_file_name="${2}"

    save_config_vars "${config_file_name}" REMOTE_STATE_SA

    REMOTE_STATE_RG=$(az resource list --name ${REMOTE_STATE_SA} | jq --raw-output '.[0].resourceGroup')
    fail_if_null REMOTE_STATE_RG
    tfstate_resource_id=$(az resource list --name ${REMOTE_STATE_SA} | jq --raw-output '.[0].id')
    fail_if_null tfstate_resource_id
    STATE_SUBSCRIPTION=$(echo $tfstate_resource_id | cut -d/ -f3 | tr -d \" | xargs)
    
    save_config_vars "${config_file_name}" \
        REMOTE_STATE_RG \
        tfstate_resource_id \
        STATE_SUBSCRIPTION





}
