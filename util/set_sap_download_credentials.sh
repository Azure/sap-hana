#!/usr/bin/env bash

###############################################################################
#
# Purpose:
# This script simplifies the user interaction with the JSON input templates so
# the user does not need to manually edit JSON files when configuring their SAP
# Launchpad access credentials for downloading SAP install media.
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

	local sap_username="$1"
	local sap_password="$2"
	local template_name="$3"

	edit_json_template_for_sap_credentials "${sap_username}" "${sap_password}" "${template_name}"
}


function check_command_line_arguments()
{
	local args_count=$#

	# Check there're just two arguments provided
	if [[ ${args_count} -ne 3 ]]; then
		echo "Available Templates:"
		list_available_templates
		error_and_exit "You must specify 3 command line arguments for the SAP download credentials: a username, a password, and the template name"
	fi
}


function list_available_templates()
{
	print_allowed_json_template_names "${target_template_dir}" | grep 'hana'
}


function edit_json_template_for_sap_credentials()
{
	local sap_username="$1"
	local sap_password="$2"
	local json_template_name="$3"

	# Escape the SAP Credentials
	sap_username=$(get_escaped_string "${sap_username}")
	sap_password=$(get_escaped_string "${sap_password}")

	# these are the JSON path in jq format
	local sap_username_json_path='"software", "downloader", "credentials", "sap_user"'
	local sap_password_json_path='"software", "downloader", "credentials", "sap_password"'

	# Only attempt to set for non-empty usernames
	if [[ "${sap_username}" != "" ]]; then
		edit_json_template_for_path "${sap_username_json_path}" "${sap_username}" "${json_template_name}"
	fi

	# Only attempt to set for non-empty passwords
	if [[ "${sap_password}" != "" ]]; then
		edit_json_template_for_path "${sap_password_json_path}" "${sap_password}" "${json_template_name}"
	fi
}


# Execute the main program flow with all arguments
main "$@"
