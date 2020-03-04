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


readonly input_file_term='<JSON template name>'
readonly target_path="deploy/v2"
readonly target_code="${target_path}/terraform/"
readonly target_template_dir="${target_path}/template_samples"


function main()
{

	# default to empty string when 0 args supplied
	local terraform_action=''
	[ $# -eq 0 ] || terraform_action="$1"

	# default to empty string when 1 or less args supplied
	local template_name=''
	[ $# -le 1 ] || template_name="$2"

	# dispatch appropriate command
	case "${terraform_action}" in
		'init')
			terraform_init
			;;
		'apply')
			check_command_line_arguments_for_template "$@"
			terraform_apply "${template_name}"
			;;
		'destroy')
			check_command_line_arguments_for_template "$@"
			terraform_destroy "${template_name}"
			;;
		*)
			print_usage_info_and_exit
			;;
	esac
}


# This function checks the command line arguments for the case when a template
# name is required
function check_command_line_arguments_for_template()
{
	local args_count=$#
	local script_name="$0"
	local terraform_action="$1"

	# Check there're just two arguments provided
	if [[ ${args_count} -ne 2 ]]; then
		print_usage_info
		error_and_exit "You must specify a ${input_file_term} to run ${script_name} with the '${terraform_action}' option"
	fi
}


# Initialize Terraform using the target code
function terraform_init()
{
	run_terraform_command "init ${target_code}"
}


# Apply Terraform target code
function terraform_apply()
{
	local target_json_template="$1"

	check_json_template_exists "${target_json_template}"

	local target_json
	target_json=$(get_json_template_path "${target_json_template}")
	run_terraform_command "apply -auto-approve -var-file=${target_json} ${target_code}"
}


# Destroy Azure resources using the Terraform target code
function terraform_destroy()
{
	local target_json_template="$1"

	check_json_template_exists "${target_json_template}"

	local target_json
	target_json=$(get_json_template_path "${target_json_template}")
	run_terraform_command "destroy -auto-approve -var-file=${target_json} ${target_code}"
}


# This function prints the correct/expected script usage but does not exit
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
	echo -e "\tapply ${input_file_term}"
	echo -e "\tdestroy ${input_file_term}"
	echo
	echo "Where ${input_file_term} is one of the following:"
	print_allowed_json_template_names
	echo
}


# This function prints the correct/expected script usage and then exits
function print_usage_info_and_exit()
{
	print_usage_info
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


# Given a template file name (without file extension)
# This function returns the full relative path of the template file
function get_json_template_path()
{
	local template_name="$1"

	local json_template_path="${target_template_dir}/${template_name}.json"

	echo "${json_template_path}"
}


# Given a template file name (without file extension)
# This function determines if the template file exists, and exits with an
# error and usage info when no template is found
function check_json_template_exists()
{
	local template_name="$1"

	local template_path
	template_path=$(get_json_template_path "${template_name}")

	if [ ! -f "${template_path}" ]; then
		print_usage_info
		error_and_exit "'${template_name}' is not a valid ${input_file_term} to use with the '${terraform_action}' option"
	fi
}


# This function pretty prints all the currently available template file names
function print_allowed_json_template_names()
{
	# list JSON files in the templates dir
	# filter the output of 'find' to extract just the filenames without extensions
	# prefix the results with indents and hyphen bullets
	find ${target_template_dir} -name '*.json' | sed -e 's/.*\/\(.*\)\.json/  - \1/'
}


# Execute the main program flow with all arguments
main "$@"
