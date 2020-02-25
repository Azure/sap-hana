#!/usr/bin/env bash

###############################################################################
#
# Purpose:
# This script simplifies the user interaction with Azure to determine the
# currently configured subscription.
#
###############################################################################

# exit immediately if an unset variable is used
set -o nounset

# import common functions that are reused across scripts
source util/common_utils.sh


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


# Execute the main program flow with all arguments
main "$@"
