#!/usr/bin/env bash

###############################################################################
#
# Purpose:
# This script simplifies the user interaction with terraform for V2 of the
# codebase by removing the need to specify complex command line options and
# allowing terraform to run from the project root directory.
#
# The script supports terraform options for: init, apply, and destroy.
#
###############################################################################

# exit immediately if a command fails
set -o errexit

# exit immediately if an unset variable is used
set -o nounset

# import common functions that are reused across scripts
source util/common_utils.sh


readonly target_path="deploy/v2"
readonly target_code="${target_path}/terraform/"
readonly target_json="${target_path}/template_samples/single_node_hana.json"


function main()
{
	# handle no command being supplied
	local terraform_action=''
	[ $# -eq 0 ] || terraform_action="$1"

	# dispatch appropriate command
	case "${terraform_action}" in
		'init')
			terraform_init
			;;
		'apply')
			terraform_apply
			;;
		'destroy')
			terraform_destroy
			;;
		*)
			print_usage_info
			;;
	esac
}


# Initialize Terraform using the target code
function terraform_init()
{
	run_terraform_command "init ${target_code}"
}


# Apply Terraform target code
function terraform_apply()
{
	run_terraform_command "apply -auto-approve -var-file=${target_json} ${target_code}"
}


# Destroy Azure resources using the Terraform target code
function terraform_destroy()
{
	run_terraform_command "destroy -auto-approve -var-file=${target_json} ${target_code}"
}


# Print the correct/expected script usage
function print_usage_info()
{
	local script_path="$0"

	echo
	echo "Usage:"
	echo
	echo -e "\t${script_path} <command>"
	echo
	echo "The commands are:"
	echo -e "\tinit"
	echo -e "\tapply"
	echo -e "\tdestroy"
	echo
	exit 2
}


# Runs Terraform with the provided command line options
function run_terraform_command()
{
	local options="$1"

	local command="terraform ${options}"

	# describe the command that will be run (useful for debugging)
	echo "Running the following Terraform command:"
	echo
	echo "${command}"
	echo

	${command}
}

# Execute the main program flow with all arguments
main "$@"
