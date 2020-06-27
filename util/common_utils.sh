#!/usr/bin/env bash

###############################################################################
#
# Purpose:
# This file allows bash functions to be used across different scripts without
# redefining them in each script. It's designed to be "sourced" rather than run
# directly.
#
###############################################################################

readonly target_path="${SCRIPTPATH}/../deploy"
# location of the input JSON templates
readonly target_template_dir="${target_path}/template_samples"


# Given a return/exit status code (numeric argument)
#   and an error message (string argument)
# This function returns immediately if the status code is zero.
# Otherwise it prints the error message to STDOUT and exits.
# Note: The error is prefixed with "ERROR: " and is sent to STDOUT, not STDERR
function continue_or_error_and_exit()
{
	local status_code=$1
	local error_message="$2"

	((status_code != 0)) && { error_and_exit "${error_message}"; }

	return "${status_code}"
}


function error_and_exit()
{
	local error_message="$1"

	printf "%s\n" "ERROR: ${error_message}" >&2
	exit 1
}


function check_file_exists()
{
	local file_path="$1"

	if [ ! -f "${file_path}" ]; then
		error_and_exit "File ${file_path} does not exist"
	fi
}


# This function pretty prints all the currently available template file names
function print_allowed_json_template_names()
{
	local target_dir="$1"

	# list JSON files in the templates dir
	# filter the output of 'find' to extract just the filenames without extensions
	# prefix the results with indents and hyphen bullets
	find "${target_dir}" -name '*.json' | sed -e 's/.*\/\(.*\)\.json/  - \1/'
}


# This function will check to see if the given command line tool is installed
# If the command is not installed, then it will exit with an appropriate error and the given advice
function check_command_installed()
{
	local cmd="$1"
	local advice="$2"

	# disable exit on error throughout this section as it's designed to fail
	# when cmd is not installed
	set +e
	local is_cmd_installed
	command -v "${cmd}" > /dev/null
	is_cmd_installed=$?
	set -e

	local error="This script depends on the '${cmd}' command being installed"
	# append advice if any was provided
	if [[ "${advice}" != "" ]]; then
		error="${error} (${advice})"
	fi

	continue_or_error_and_exit ${is_cmd_installed} "${error}"
}


# This function sets the JSON value at the given JSON path to the given value in the given JSON template file
# Note: It uses the `jq` command line tool, and will fail with a helpful error if the tool is not installed.
function edit_json_template_for_path()
{
	local json_path="$1"
	local json_value="$2"
	local json_template_name="$3"
	local target_json="${target_template_dir}/${json_template_name}.json"
	local temp_template_json="${target_json}.tmp"

	check_file_exists "${target_json}"

	check_command_installed 'jq' 'Try: https://stedolan.github.io/jq/download/'

	# this is the JSON path in jq format
	# in the future we could call a function here to translate simple dot-based paths into jq format paths
	# For example: Translate 'infrastructure.resource_group.name' to '"infrastructure", "resource_group", "name"'
	local jq_json_path="${json_path}"
	local jq_command="jq --arg value ${json_value} 'setpath([${jq_json_path}]; \$value)' \"${target_json}\""

	# edit JSON template file contents and write to temp file
	eval "${jq_command}" > "${temp_template_json}"

	# replace original JSON template file with temporary edited one
	mv "${temp_template_json}" "${target_json}"
}


# This helper funciton checks if a JSON key is set to a non-empty string
# the json_path argument must be in jq dot notation, e.g. '.software.downloader.credentials.sap_user'
function check_json_value_is_not_empty()
{
	local json_path="$1"
	local json_template_name="$2"
	local target_json="${target_template_dir}/${json_template_name}.json"

	check_file_exists "${target_json}"

	check_command_installed 'jq' 'Try: https://stedolan.github.io/jq/download/'

	local json_value=
	json_value=$(jq "${json_path}" "${target_json}")

	if [ "${json_value}" == '""' ]; then
		return 1
	else
		return 0
  fi
}


# This function is used to compare semver strings
# It takes two parameters, each a semver string /\d+(\.\d+(\.\d+)?)?/
# For example, 1, 1.2, 1.2.3 and compares them
# It echos ">" if string1 > string2, "=" if string1 == string2 and "<" if string1 < string2
function test_semver()
{
	local actual_semver="$1"
	local required_semver="$2"

	IFS=. read -r -a actual_semver_parts <<< "${actual_semver}"
	IFS=. read -r -a required_semver_parts <<< "${required_semver}"

	(( major=${actual_semver_parts[0]:-0} - ${required_semver_parts[0]:-0} ))
	if [[ ${major} -ne 0 ]]; then
		[[ ${major} -gt 0 ]] && echo -n ">" || echo -n "<"
	else
		(( minor=${actual_semver_parts[1]:-0} - ${required_semver_parts[1]:-0} ))
		if [[ ${minor} -ne 0 ]]; then
			[[ ${minor} -gt 0 ]] && echo -n ">" || echo -n "<"
		else
			(( patch=${actual_semver_parts[2]:-0} - ${required_semver_parts[2]:-0} ))
			# shellcheck disable=SC2015
			[[ ${patch} -gt 0 ]] && echo -n ">" || ( [[ ${patch} -eq 0 ]] && echo -n "=" || echo -n "<" )
		fi
	fi
}


# This function takes a single bash string and escapes all special characters within it
# Source: https://stackoverflow.com/a/20053121
function get_escaped_string()
{
	local str="$1"
	echo "$str" | sed -e 's/[^a-zA-Z0-9,._+@%/-]/\\&/g; 1{$s/^$/""/}; 1!s/^/"/; $!s/$/"/'
}
