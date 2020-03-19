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
source util/common_utils.sh


# location of the input JSON template
readonly target_path="deploy/v2"
# readonly target_code="${target_path}/terraform/"
readonly target_json_dir="${target_path}/template_samples"


function main()
{
	check_command_line_arguments "$@"

	local template_name="$1"
	local sap_username="$2"
	local sap_password="$3"

	edit_json_template_for_sap_credentials "${template_name}" "${sap_username}" "${sap_password}"
}


function check_command_line_arguments()
{
	local args_count=$#

	# Check there're just two arguments provided
	if [[ ${args_count} -ne 3 ]]; then
		error_and_exit "You must specify 3 command line arguments for the SAP download credentials: the template name, a username and a password"
	fi
}


function edit_json_template_for_sap_credentials()
{
	local template_name="$1"
	local sap_username="$2"
	local sap_password="$3"

	# use temp file method to avoid BSD sed issues on Mac/OSX
	# See: https://stackoverflow.com/questions/5694228/sed-in-place-flag-that-works-both-on-mac-bsd-and-linux/5694430#5694430
	local target_json="${target_json_dir}/${template_name}.json"
	local temp_template_json="${target_json}.tmp"

	check_file_exists "${target_json}"

	# filter JSON template file contents and write to temp file
	sed -e "s/\(.*\"sap_user\": \)\".*\(\"\)/\1\2${sap_username}\"/" \
		-e "s/\(.*\"sap_password\": \)\".*\(\"\)/\1\2${sap_password}\"/" \
		"${target_json}" > "${temp_template_json}"

    # replace original JSON template file with temporary filtered one
    mv "${temp_template_json}" "${target_json}"
}


# Execute the main program flow with all arguments
main "$@"
