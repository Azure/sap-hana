#!/usr/bin/env bash

###############################################################################
#
# Purpose:
# This file allows bash functions to be used across different scripts without
# redefining them in each script. It's designed to be "sourced" rather than run
# directly.
#
###############################################################################


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
