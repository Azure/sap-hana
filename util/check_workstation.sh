#!/usr/bin/env bash

###############################################################################
#
# Purpose:
# This script simplifies the user interaction with various tools on their
# operating system to ensure they have versions that meet the project's
# requirements.
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
	# Display installed version for required tools

	# Azure CLI
	display_tool_version "az"

	# Terraform
	display_tool_version "terraform"

	# Ansible
	display_tool_version "ansible"

	# JQ
	display_tool_version "jq"
}


# Given a command line tool (string argument)
# This function returns/prints to STDOUT the tool's name and semantic version
# Example: "MyToolV3................v1.20.321 (latest)" should become "MyToolV3 = 1.20.321"
# Note: The tool must support the --version option and the version must be in the first line of output
function display_tool_version()
{
	local tool="$1"

	# The following filtering command should extract the tool name and a 3-part semantic version
	# Note: Mac/OSX uses BSD sed by default that does not support [0-9]+ so use [0-9][0-9]*
	local filter_cmd="sed -e 's/^\([A-Za-z0-9-]*\).*\([0-9][0-9]*\.[0-9][0-9]*[\.-][0-9][0-9]*\).*/\2/' -e 'tx' -e 'd' -e ':x'"

	# jq does not conform to Semver
	[[ "$tool" == "jq" ]] && filter_cmd="sed -e 's/^\jq-\([0-9][0-9]*\.[0-9][0-9]*\).*/\1/' -e 'tx' -e 'd' -e ':x'"

	local tool_output
	# Get first line of version output and truncate spaces
	tool_output=$(eval "${tool} --version | head -1 | tr -s ' ' | ${filter_cmd}")

	echo -e "${tool} = ${tool_output}"
}


# Execute the main program flow with all arguments
main "$@"
