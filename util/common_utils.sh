#!/usr/bin/env bash

###############################################################################
#
# Purpose:
# This file allows bash functions to be used across different scripts without
# redefining them in each script. It's designed to be "sourced" rather than run
# directly.
#
###############################################################################


function print_line()
{
	# default line if not supplied
	local line=''
	[ $# -eq 0 ] || line="$1"

	echo -e "${line}"
}


function print_tabbed_line()
{
	# default line if not supplied
	local line=''
	[ $# -eq 0 ] || line="$1"

	print_line "\t${line}"
}


function run_command()
{
	local command="$1"

	# run the command
	${command}
}


# Given a return/exit status code (numeric argument)
#   and an error message (string argument)
# This function returns immediately if the status code is zero.
# Otherwise it prints the error message to STDOUT and exits.
# Note: The error is prefixed with "ERROR: " and is sent to STDOUT, not STDERR
function continue_or_error_and_exit()
{
	local status_code=$1
	local error_message="$2"

	((status_code != 0)) && { echo "ERROR: ${error_message}"; exit 1; }
}
