#!/usr/bin/env bash

###############################################################################
#
# Purpose:
# This script simplifies the user interaction with the JSON input templates so
# the user does not need to manually edit JSON files when configuring the
# required OS for their SAP VMs.
#
###############################################################################

# exit immediately if a command fails
set -o errexit

# exit immediately if an unset variable is used
set -o nounset

# import common functions that are reused across scripts
# shellcheck disable=SC1091
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
source "${SCRIPTPATH}/common_utils.sh"

readonly list_of_offers="${SCRIPTPATH}/sap_os_offers.json"

function main()
{
	check_command_line_arguments "$@"

	local args_count=$#
	local sap_os="$1"
	local template_name="$2"
	local section="all"
	if [[ ${args_count} -eq 3 ]]; then
		section="$3"
	fi

	edit_json_template_for_sap_os "${sap_os}" "${template_name}" "${section}"
}


function check_command_line_arguments()
{
	local args_count=$#
	local usage="Usage: ${0} \"<SAP OS offer>\" \"<template name>\" [app|hdb]"

	# Check there are just two arguments provided
	if [[ ${args_count} -ne 2 && ${args_count} -ne 3 ]]; then
		echo "${usage}"
		echo
		echo "If 'app' or 'hdb' is specified as the third argument, then only the OS for that section is changed"
		echo
		echo "Available SAP OS offers:"
		list_available_offers
		echo
		echo "Available Templates:"
		list_available_templates
		echo
		if [[ ${args_count} -eq 0 ]]; then
			# No arguments: just show the help and exit gracefully
			exit
		else
			# Incorrect number of arguments
			error_and_exit "${usage}"
		fi
	fi
}


function list_available_templates()
{
	# shellcheck disable=SC2154
	print_allowed_json_template_names "${target_template_dir}" | grep 'hana' | sort
}


function list_available_offers()
{
	jq 'keys_unsorted' "${list_of_offers}" | sed -n -e '/[a-zA-Z]/s/^[^"]*"\([^"]*\).*/  - \1/gp'
}


function edit_json_template_for_sap_os()
{
	local sap_os
	sap_os="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
	local json_template_name="$2"
	local section="$3"
	local target_json="${target_template_dir}/${json_template_name}.json"
	local temp_template_json="${target_json}.tmp"

	# This sets stored values from the sap_os_offers.json
	# Check if the passed in value is known
	if list_available_offers | grep -q "^  - ${sap_os}$" 2>/dev/null; then
		local sap_os_publisher
		local sap_os_offer
		local sap_os_sku
		sap_os_publisher=$(jq ".${sap_os}.publisher" "${list_of_offers}")
		sap_os_offer=$(jq ".${sap_os}.offer" "${list_of_offers}")
		sap_os_sku=$(jq ".${sap_os}.sku" "${list_of_offers}")

	else
		# Passed in value is unknown
		echo "Available SAP OS offers:"
		list_available_offers
		error_and_exit "${sap_os} is not a recognised SAP OS offer"
	fi

	# Ensure the template name is known
	if ! list_available_templates | grep -q "^  - ${json_template_name}$" 2>/dev/null; then
		echo "Available Templates:"
		list_available_templates
		echo
		error_and_exit "${json_template_name} is not a recognised template"
	fi

	# We need the jq "walk" function from v1.6: https://stedolan.github.io/jq/manual/#walk(f)
	local jq_version
	jq_version=$(jq --version | cut -f2 -d-)
	local jq_def_walk
	if [[ $(test_semver "${jq_version}" "1.6") == "<" ]]; then
		# Build it by hand if jq is pre-1.6
		# https://github.com/stedolan/jq/blob/ccc79e592cfe1172db5f2def5a24c2f7cfd418bf/src/builtin.jq#L255-L262
		# shellcheck disable=2016
		jq_def_walk='def walk(f):
			. as $in | if type == "object" then
				reduce keys_unsorted[] as $key ( {}; . + { ($key): ($in[$key] | walk(f)) } ) | f
			elif type == "array" then map( walk(f) ) | f
			else f end;'
	else
		jq_def_walk=""
	fi

	# For the HANA Database tier
	# Always set new values, regardless of any values already present
	# Using the "walk" function, follow the JSON tree looking for arrays
	# When an array is found, map each element. For each element:
	#   If it contains a "platform" property with the value "HANA", then:
	#    If it has an "os" property having a "publisher"/"offer"/"sku" property, then:
	#      Replace the value of the appropriate property.
	if [[ "${section}" == "all" || "${section}" == "hdb" ]]; then
		jq "${jq_def_walk}
				walk(if type == \"array\" then
					map(select(.platform? == \"HANA\") .os?={
							publisher: ${sap_os_publisher},
							offer: ${sap_os_offer},
							sku: ${sap_os_sku} } )
					else . end)" "${target_json}" >"${temp_template_json}" && mv "${temp_template_json}" "${target_json}"
	fi

	# For the Application tier.
	if [[ "${section}" == "all" || "${section}" == "app" ]]; then
		jq ".application.os?={
			publisher: ${sap_os_publisher},
			offer: ${sap_os_offer},
			sku: ${sap_os_sku}
		}" "${target_json}" >"${temp_template_json}" && mv "${temp_template_json}" "${target_json}"
	fi
}

# Execute the main program flow with all arguments
main "$@"
