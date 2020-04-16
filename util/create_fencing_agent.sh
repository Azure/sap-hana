#!/usr/bin/env bash
#
#######################################################################################################################################################
#
# This script simplifies the user interaction with Azure to create a fencing
# agent service principal and grant the required permissions to manage resources.
# This script is essentially wrapping the process described here:
# https://docs.microsoft.com/en-us/azure/virtual-machines/workloads/sap/high-availability-guide-suse-pacemaker#create-azure-fence-agent-stonith-device
#
#######################################################################################################################################################

# exit immediately if an unset variable is used
set -o nounset

# import common functions that are reused across scripts
source util/common_utils.sh

# name of the script where the auth info will be saved
readonly auth_script="set-clustering-auth-${1-}.sh"

# link for service principal help
readonly sp_link='https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli'

function main()
{
	check_command_line_arguments "$@"

	local SID="${1-}"

	create_service_principal_script "${SID}"
}


function check_command_line_arguments()
{
	local args_count="$#"

	# Check there's just a single argument provided
	if [[ ${args_count} -ne 1 ]]; then
		error_and_exit "You must specify a single command line argument for the SAP SID. For example: $0 HN1"
	fi
}


function create_service_principal_script()
{
	local service_principal_name="fencing-agent-${SID}"

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

	# create new script for authorization
	cat <<- EOF > "${auth_script}"
		export SAP_HANA_FENCING_AGENT_SUBSCRIPTION_ID=${subscription_id}
		export SAP_HANA_FENCING_AGENT_TENANT_ID=${tenant_id}
		export SAP_HANA_FENCING_AGENT_CLIENT_ID=${client_id}
		export SAP_HANA_FENCING_AGENT_CLIENT_SECRET=${client_secret}
	EOF

	# Define subscription id in json role template
	template_file='util/fencing_agent_role.json'
	az_subscription_id=$(echo "${subscription_id}" | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/')
	# use temp file method to avoid BSD sed issues on Mac/OSX
	# See: https://stackoverflow.com/questions/5694228/sed-in-place-flag-that-works-both-on-mac-bsd-and-linux/5694430#5694430
	local temp_template_json="${template_file}.tmp"

	# filter JSON template file contents and write to temp file
	sed -e "s/SUBSCRIPTION_ID/${az_subscription_id}/" \
		"${template_file}" > "${temp_template_json}"

	# replace original JSON template file with temporary filtered one
	mv "${temp_template_json}" "${template_file}"

	# ensure role definition exsits
	local fencing_template='Linux Fence Agent Role'
	local sp_prefix='http://'
	role_list="$(az role definition list --name 'Linux Fence Agent Role')"
	if [[ "${role_list}" == "[]" ]]; then
		az role definition create --role-definition "${template_file}"
	else echo "Role definition already exists"
	fi
	# ensure role is assigned to fencing service principal
	assignment_list="$(az role assignment list --assignee "${sp_prefix}${service_principal_name}" --role "${fencing_template}")"
	if [[ "${assignment_list}" == "[]" ]]; then
		az role assignment create --assignee "${sp_prefix}${service_principal_name}" --role "${fencing_template}"
	else echo "Role assignment already exists"
	fi

	IFS="${ifs_backup}"

	echo "A service principal has been created in Azure > App registrations, with the name: ${service_principal_name}"
	echo "Azure authorization details can be found within the script: ${auth_script}"
	echo "The Azure authorization details are copied to the RTI during Terraform provisioning for usage by Ansible."

}

function check_auth_script_does_not_exist()
{
	[ ! -f "${auth_script}" ]
	auth_exists=$?
	continue_or_error_and_exit "$auth_exists" "Authorization file already exists: ${auth_script}. Please reuse, move, or remove it."
}

# Execute the main program flow with all arguments
main "$@"

# revert json template back to original state
git checkout util/fencing_agent_role.json
