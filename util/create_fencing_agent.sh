#!/usr/bin/env bash

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
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
source "${SCRIPTPATH}/common_utils.sh"

# name of the script where the auth info will be saved
readonly auth_script="export-clustering-sp-details.sh"

# Terraform workspace to save the script into
readonly terraform_workspace="$( terraform workspace show )"

# link for service principal help
readonly sp_link='https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli'


function main()
{
	check_command_line_arguments "$@"

	local SID="${1-}"

	# one shared role is used across all SAP fencing agents
	local fencing_agent_role_name='SAP HANA Linux Fencing Agent'

	# one dedicated fencing agent is created per SAP HANA SID
	local service_principal_name="sap-hana-${SID}-fencing-agent"

	# lookup subscription ID for creation of the role and the SP config script
	local subscription_id=''
	subscription_id=$(lookup_subscription_id)

	# create and configure the Azure resources/identities/etc.
	create_fencing_agent_role "${fencing_agent_role_name}" "${subscription_id}"
	create_service_principal_and_config_script "${service_principal_name}" "${subscription_id}"
	assign_fencing_agent_role_to_service_principal "${service_principal_name}" "${fencing_agent_role_name}"

	echo "A role has been created in the Azure subscription ${subscription_id}, with the name: ${service_principal_name}"
	echo "A fencing agent has been created in Azure > App registrations, with the name: ${service_principal_name}"
	echo "The role has been assigned to the fencing agent"
	echo "The fencing agent authorization details can be found within the script: ${terraform_workspace}/${auth_script}"
	echo "The authorization details are copied to the RTI during Terraform provisioning for usage by Ansible."
}


function check_command_line_arguments()
{
	local args_count="$#"

	# Check there's just a single argument provided
	if [[ ${args_count} -ne 1 ]]; then
		error_and_exit "You must specify a single command line argument for the SAP SID. For example: HN1"
	fi
}


function lookup_subscription_id()
{
	# Attempt to obtain the Azure subscription ID via CLI
	local subscription_id=''
	subscription_id=$(az account show --query 'id' | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/')

	# Check for success and error on failure
	local subscription_id_status=$?
	continue_or_error_and_exit $subscription_id_status "There was a problem obtaining the Azure subscription ID. If you are logged into Azure CLI, then it could relate to lack of network connectivity."

	# Return the result
	echo -e "${subscription_id}"
}


function create_fencing_agent_role()
{
	local fencing_agent_role_name="$1"
	local subscription_id="$2"

	local fencing_agent_template_file="${SCRIPTPATH}/fencing_agent_role.json"

	# Step 1 of 3: Replace tokens for ROLE_NAME and SUBSCRIPTION_ID in the role definition template

	# Note: use temp file method to avoid BSD sed issues on Mac/OSX
	# See: https://stackoverflow.com/questions/5694228/sed-in-place-flag-that-works-both-on-mac-bsd-and-linux/5694430#5694430

	# filter JSON template file contents and write to temp file
	local temp_fencing_agent_template_file="${fencing_agent_template_file}.tmp"
	sed \
		-e "s/ROLE_NAME/${fencing_agent_role_name}/" \
		-e "s/SUBSCRIPTION_ID/${subscription_id}/" \
		"${fencing_agent_template_file}" > "${temp_fencing_agent_template_file}"

	# replace original JSON template file with temporary filtered one
	mv "${temp_fencing_agent_template_file}" "${fencing_agent_template_file}"

	# Step 2 of 3: Create the role definition in Azure if it doesn't exist already
	local role_list=''
	role_list=$(az role definition list --name "${fencing_agent_role_name}")
	local role_list_status=$?
	continue_or_error_and_exit $role_list_status "There was a problem determining if the Fencing Agent role already exists. If you are logged into Azure CLI, then it could relate to lack of network connectivity."

	# check if fencing agent role already exists and create it if not
	if [[ "${role_list}" == "[]" ]]; then
		az role definition create --role-definition "${fencing_agent_template_file}" > /dev/null
		local role_creation_status=$?
		continue_or_error_and_exit $role_creation_status "There was a problem creating the Fencing Agent role. If you are logged into Azure CLI, then it could relate to lack of network connectivity."
	else
		echo "Role definition already exists"
	fi

	# Step 3 of 3: Restore template changes from step 1
	git checkout "${fencing_agent_template_file}"
}


function create_service_principal_and_config_script()
{
	local service_principal_name="$1"
	local subscription_id="$2"

	check_terraform_workspace_dir_does_not_exist

	check_auth_script_does_not_exist

	# ensure newlines in variable values are preserved
	# backup current value to restore to afterwards
	local ifs_backup="${IFS}"
	IFS=$'\n'

	# create the service principal and capture the output
	local sp_details=''
	sp_details=$(az ad sp create-for-rbac --name "${service_principal_name}")
	local sp_creation_status=$?
	# check the SP was created successfully
	continue_or_error_and_exit $sp_creation_status "There was a problem creating the service principal. If you are logged into Azure CLI, then it could relate to lack of admin/owner permissions. See ${sp_link} for further details."

	local tenant_id=''
	tenant_id=$(az account show --query 'tenantId')
	local tenant_id_status=$?
	continue_or_error_and_exit $tenant_id_status "There was a problem obtaining the Azure tenant ID. If you are logged into Azure CLI, then it could relate to lack of network connectivity."

	local client_id=''
	client_id=$(echo "${sp_details}"  | grep appId | sed -e 's/.*appId.:.\(.*\),/\1/')

	local client_secret=''
	client_secret=$(echo "${sp_details}" | grep password | sed -e 's/.*password.:.\(.*\),/\1/')

	# create new script for authorization
	cat <<- EOF > "${terraform_workspace}/${auth_script}"
		export SAP_HANA_FENCING_AGENT_SUBSCRIPTION_ID=${subscription_id}
		export SAP_HANA_FENCING_AGENT_TENANT_ID=${tenant_id}
		export SAP_HANA_FENCING_AGENT_CLIENT_ID=${client_id}
		export SAP_HANA_FENCING_AGENT_CLIENT_SECRET=${client_secret}
	EOF

	IFS="${ifs_backup}"
}


function assign_fencing_agent_role_to_service_principal()
{
	local service_principal_name="$1"
	local fencing_agent_role_name="$2"

	# ensure fencing agent role is assigned to fencing agent service principal
	local sp_uri="http://${service_principal_name}"

	local assignment_list=''
	assignment_list="$(az role assignment list --assignee "${sp_uri}" --role "${fencing_agent_role_name}")"
	local assignment_list_status=$?
	continue_or_error_and_exit $assignment_list_status "There was a problem determining if the Fencing Agent role has already been assigned. If you are logged into Azure CLI, then it could relate to lack of network connectivity."
	# check if fencing agent role assignment exists and create it if not
	if [[ "${assignment_list}" == "[]" ]]; then
		az role assignment create --assignee "${sp_uri}" --role "${fencing_agent_role_name}" > /dev/null
		local assignment_creation_status=$?
		continue_or_error_and_exit $assignment_creation_status "There was a problem creating the Fencing Agent role assigment. If you are logged into Azure CLI, then it could relate to lack of network connectivity."
	else
		echo "Role assignment already exists"
	fi
}


function check_terraform_workspace_dir_does_not_exist()
{
	[ ! -d "${terraform_workspace}" ]
	mkdir -p "${terraform_workspace}"
}

function check_auth_script_does_not_exist()
{
	[ ! -f "${terraform_workspace}/${auth_script}" ]
	auth_exists=$?
	continue_or_error_and_exit "$auth_exists" "Authorization file already exists: ${terraform_workspace}/${auth_script}. Please reuse, move, or remove it."
}


# Execute the main program flow with all arguments
main "$@"
