#!/usr/bin/env bash

# exit immediately if an unsed variable is used
set -o nounset


function main()
{
	display_subscription_info
}


function display_subscription_info()
{
	local return_status

	# extract only the required info for a subscription
	local subscription_info
	subscription_info=$(az account show --query "{name:name,id:id}")
	return_status=$?

	# check for failure and make a suggestion
	continue_or_error_and_exit $return_status "Unable to determine subscription information. Check you're logged in and a subscription has been set."

	# Parse the subscription Name and ID
	local subscription_name
	local subscription_id
	subscription_name=$(echo "${subscription_info}" | grep '"name":' | cut -d'"' -f4)
	subscription_id=$(echo "${subscription_info}" | grep '"id":' | cut -d'"' -f4)

	echo -e "Your current subscription is ${subscription_name} (ID=${subscription_id})"
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


# Execute the main program flow with all arguments
main "$@"
