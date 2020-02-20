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