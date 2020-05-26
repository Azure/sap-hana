#!/usr/bin/env bash

############################################################################################
#
# This script acts as a simple interface to a playbook to test the cluster after deployment.
#
# This script assumes the cluster has been deployed via the Terraform, and is being run
# on the RTI instance.
#
############################################################################################

# exit immediately if an unset variable is used
set -o nounset

function main()
{
	check_command_line_arguments "$@"

	local FAILOVER_TYPE="$1"

	# Playbook converts failover_test_type to lower case
	ansible-playbook -i ~/hosts ~/sap-hana/deploy/ansible/test_failover.yml -e "failover_test_type=${FAILOVER_TYPE}"
}


function check_command_line_arguments()
{
	local args_count="$#"

	# Check there's just a single argument provided
	if [[ ${args_count} -ne 1 ]]; then
		printf "%s\n" "You must specify a single command line argument for the failover test type. Valid types:"
		printf "  - %s\n" "migrate      - Test migration of Master node"
		printf "  - %s\n" "fence_agent  - Test the Fencing Agent by making the network interface unavailable"
		printf "  - %s\n" "service      - Test failover by stopping the cluster service"
		exit 1
	fi
}

main "$@"
