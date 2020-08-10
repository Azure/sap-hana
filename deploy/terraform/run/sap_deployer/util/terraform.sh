#!/usr/bin/env bash

###############################################################################
#
# Purpose:
# This script enables the user modification of deployer(s) related resources at
# post-deployment stage via Terraform.
#
# Usage:
# util/terraform.sh
#
###############################################################################

# exit immediately if a command fails
set -o errexit

# exit immediately if an unset variable is used
set -o nounset

readonly target_json="$HOME/.config/sa_config.json"

SCRIPT=$(readlink -f "$0")
# Absolute path this script
SCRIPTPATH=$(dirname "$SCRIPT")

# file will be put in the current working directory
local_file_dir="${SCRIPTPATH}/../"

function main(){

    local input_json_name="deployer.json"
    local input_json_path="${local_file_dir}${input_json_name}"

    check_file_exists ${input_json_path} "Please prepare an input json ${input_json_path}"

    check_file_exists ${target_json} "Please follow guidance to recover it"

    check_jq_installed

    local saplibrary_resource_group_name=$(read_json .saplibrary.resource_group_name)
    local storage_account_name=$(read_json .saplibrary.storage_account_name)
    local container_name="deployer"
    local tfstate_path="deployer.terraform.tfstate"

    terraform_execute ${saplibrary_resource_group_name} ${storage_account_name} ${container_name} ${input_json_path} ${tfstate_path}
    
}

function check_file_exists(){

    local file_path="$1"
    local error_msg="$2"
    
    if [ ! -f "${file_path}" ]; then
        printf "%s\n" "ERROR: File ${file_path} does not exist." >&2
        printf "%s\n" "${error_msg}" >&2
        # TODO: create a guidance about file/env recovery
        exit 1
    fi
}

function check_jq_installed(){

    local cmd="jq"
    local advice="Try: https://stedolan.github.io/jq/download/"

    # disable exit on error throughout this section as it's designed to fail
    # when cmd is not installed
    set +e
    local is_cmd_installed
    command -v "${cmd}" > /dev/null
    is_cmd_installed=$?
    set -e
    
    local error="This script depends on the '${cmd}' command being installed"
    # append advice if any was provided
    if [ ${is_cmd_installed} != 0 ]; then
        error="${error} (${advice})"
        printf "%s\n" "ERROR: ${error}" >&2
        exit 1
    fi
}

function read_json(){

    local key="$1"
    local value=$(cat ${target_json} | jq -r "${key}")
	
    echo $value
}

function terraform_execute(){

    local saplibrary_resource_group_name=$1
    local storage_account_name=$2
    local container_name=$3
    local input_json_path=$4
    local tfstate_path=$5

    cd ${local_file_dir}

    rm -rf .terraform

    terraform init -force-copy \
    -backend-config "resource_group_name=${saplibrary_resource_group_name}" \
    -backend-config "storage_account_name=${storage_account_name}" \
    -backend-config "container_name=${container_name}" \
    -backend-config "key=${tfstate_path}"

    terraform apply -var-file="${input_json_path}"
}

main "$@"
