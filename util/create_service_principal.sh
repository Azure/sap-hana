#!/usr/bin/env bash

###############################################################################
#
# Purpose:
# This script simplifies the user interaction with Azure to create a service
# principal and save the required authentication details to a script.
# This script is essentially wrapping the process described here:
# https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli
#
###############################################################################

# exit immediately if an unset variable is used
set -o nounset

# import common functions that are reused across scripts
source util/common_utils.sh


# name of the script where the auth info will be saved
readonly auth_script='set-sp.sh'

# link for service principal help
readonly sp_link='https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli'


function main()
{
	check_command_line_arguments "$@"

	local service_principal_name="$1"

	create_service_principal_script "${service_principal_name}"
}


function check_command_line_arguments()
{
	local args_count=$#

	# Check there's just a single argument provided
	if [[ ${args_count} -ne 1 ]]; then
		continue_or_error_and_exit 1 "You must specify a single command line argument for the service principal name"
	fi
}


function create_service_principal_script()
{
	local service_principal_name="$1"

	check_auth_script_does_not_exist

	echo "Creating Azure Service Principal: ${service_principal_name}..."

	# ensure newlines in variable values are preserved
	# backup current value to restore to afterwards
	local ifs_backup="${IFS}"
	IFS=$'\n'

	# create the service principal and capture the output
	sp_details=$(az ad sp create-for-rbac --name "${service_principal_name}")
	local sp_creation_status=$?

	# check the SP was created successfully
	continue_or_error_and_exit $sp_creation_status "There was a problem creating the service principal. If you are logged into Azure CLI, then it could relate to lack of admin/owner permissions. See ${sp_link} for further details."

	# determine authorization credentials
	local subscription_id
	local tenant_id
	local client_id
	local client_secret
	subscription_id=$(az account show --query 'id')
	tenant_id=$(az account show --query 'tenantId')
	client_id=$(echo "${sp_details}"  | grep appId | sed -e 's/.*appId.:.\(.*\),/\1/')
	client_secret=$(echo "${sp_details}" | grep password | sed -e 's/.*password.:.\(.*\),/\1/')

	# create new bash script for authorization
	create_new_auth_script
	append_line_to_auth_script "#!/usr/bin/env bash"
	append_line_to_auth_script "export ARM_SUBSCRIPTION_ID=${subscription_id}"
	append_line_to_auth_script "export ARM_TENANT_ID=${tenant_id}"
	append_line_to_auth_script "export ARM_CLIENT_ID=${client_id}"
	append_line_to_auth_script "export ARM_CLIENT_SECRET=${client_secret}"

	# restore to previous value
	IFS="${ifs_backup}"

	echo "A service principal has been created in Azure > App registrations, with the name: ${service_principal_name}"
	echo "Azure authorization details can be found within the script: ${auth_script}"
	echo "You can enable this authorization by sourcing the script using the following command:"
	echo "source ${auth_script}"
}


function check_auth_script_does_not_exist()
{
	[ ! -f ${auth_script} ]
	auth_exists=$?
	continue_or_error_and_exit $auth_exists "Authorization file already exists: ${auth_script}. Please reuse, move, or remove it."
}


function create_new_auth_script()
{
	# create a new empty file that can be executed
	true > ${auth_script}
	chmod 0755 ${auth_script}
}


function append_line_to_auth_script()
{
	local auth_script_line="$1"

	# append line to file
	echo "${auth_script_line}" >> ${auth_script}
}


# Execute the main program flow with all arguments
main "$@"
