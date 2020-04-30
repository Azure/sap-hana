#!/usr/bin/env bash

###############################################################################
#
# Purpose:
# This script simplifies the user interaction with the JSON input templates so
# the user does not need to manually edit JSON files when configuring the
# password for the hacluster user in a Highly Available system.
#
###############################################################################

# exit immediately if a command fails
set -o errexit

# exit immediately if an unset variable is used
set -o nounset

# import common functions that are reused across scripts
source util/common_utils.sh


function main()
{
	check_command_line_arguments "$@"

	local ha_cluster_pass="$1"
	local template_name="$2"

	edit_json_template_for_ha_cluster_pass "${ha_cluster_pass}" "${template_name}"
}


function check_command_line_arguments()
{
	local args_count=$#

	# Check there're just two arguments provided
	if [[ ${args_count} -ne 2 ]]; then
		echo "Available Templates:"
		list_available_templates
		error_and_exit "You must specify 2 command line arguments: the hacluster password, and the template name"
	fi
}


function list_available_templates()
{
	print_allowed_json_template_names "${target_template_dir}" | grep 'hana'
}


function edit_json_template_for_ha_cluster_pass()
{
	local ha_cluster_pass="$1"
	local json_template_name="$2"

	# the JSON path to update in jq format
	local ha_cluster_pass_path='"databases", ( .databases | map(.platform) | index("HANA") ), "credentials", "ha_cluster_pass"'

	# Only attempt to set for non-empty password values
	if [[ "${ha_cluster_pass}" != "" ]]; then
		edit_json_template_for_path "${ha_cluster_pass_path}" "${ha_cluster_pass}" "${json_template_name}"
	fi
}


# Execute the main program flow with all arguments
main "$@"
