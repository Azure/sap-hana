#!/usr/bin/env bash

###############################################################################
#
# Purpose:
# This script is for configuring deployment resource group name which helps
# to avoid clashes with others that might be sharing the same Azure subscription.
# It also simplifies the user interaction with the JSON input templates so
# the user does not need to manually edit JSON files when configuring their
# resource group.
#
###############################################################################

# exit immediately if a command fails
set -o errexit

# exit immediately if an unset variable is used
set -o nounset

# import common functions that are reused across scripts
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
source "${SCRIPTPATH}/common_utils.sh"


function main()
{
	check_command_line_arguments "$@"

	local resource_group="$1"
	local template_name="$2"

	edit_json_template_for_resource_group "${resource_group}" "${template_name}"
}


function check_command_line_arguments()
{
	local args_count=$#

	# Check there're just two arguments provided
	if [[ ${args_count} -ne 2 ]]; then
		echo "Available Templates:"
		list_available_templates
		error_and_exit "You must specify 2 command line arguments for the resource group: a resource group name, and the template name"
	fi
}


function list_available_templates()
{
	print_allowed_json_template_names "${target_template_dir}"
}


function edit_json_template_for_resource_group()
{
	local rg_name="$1"
	local json_template_name="$2"

	# this is the JSON path in jq format
	local rg_name_json_path='"infrastructure", "resource_group", "name"'

	# Only attempt to set for non-empty resource groups
	if [[ "${rg_name}" != "" ]]; then
		edit_json_template_for_path "${rg_name_json_path}" "${rg_name}" "${json_template_name}"
	else
		error_and_exit "The resource group name cannot be empty"
	fi
}


# Execute the main program flow with all arguments
main "$@"
