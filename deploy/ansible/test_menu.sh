#!/bin/bash

cmd_dir="$(dirname "$(readlink -e "${BASH_SOURCE[0]}")")"


#         # /*---------------------------------------------------------------------------8
#         # |                                                                            |
#         # |                             Playbook Wrapper                               |
#         # |                                                                            |
#         # +------------------------------------4--------------------------------------*/
#
#         export           ANSIBLE_HOST_KEY_CHECKING=False
#         # export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=Yes
#         # export           ANSIBLE_KEEP_REMOTE_FILES=1
#
# Example of complete run execution:
#
#         ansible-playbook                                                                \
#           --inventory   X00-hosts.yaml                                                  \
#           --user        azureadm                                                        \
#           --private-key sshkey                                                          \
#           --extra-vars="@sap-parameters.yaml"                                           \
#           playbook_00_transition_start_for_sap_install.yaml                             \
#           playbook_01_os_base_config.yaml                                               \
#           playbook_02_os_sap_specific_config.yaml                                       \
#           playbook_03_bom_processing.yaml                                               \
#           playbook_04_00_00_hana_db_install.yaml                                        \
#           playbook_05_00_00_sap_scs_install.yaml                                        \
#           playbook_05_01_sap_dbload.yaml                                                \
#           playbook_05_02_sap_pas_install.yaml                                           \
#           playbook_05_03_sap_app_install.yaml                                           \
#           playbook_05_04_sap_web_install.yaml

# The SAP System parameters file which should exist in the current directory
sap_params_file=sap-parameters.yaml

if [[ ! -e "${sap_params_file}" ]]; then
        echo "Error: '${sap_params_file}' file not found!"
        exit 1
fi

# Extract the sap_sid from the sap_params_file, so that we can determine
# the inventory file name to use.
sap_sid="$(awk '$1 == "sap_sid:" {print $2}' ${sap_params_file})"


#
# Ansible configuration settings.
#
# For more details please run `ansible-config list` and search for the
# entry associated with the specific setting.
#
export           ANSIBLE_HOST_KEY_CHECKING=False
export           ANSIBLE_INVENTORY="${sap_sid}_hosts.yaml"
export           ANSIBLE_PRIVATE_KEY_FILE=sshkey

# We really should be determining the user dynamically, or requiring
# that it be specified in the inventory settings (currently true)
export           ANSIBLE_REMOTE_USER=azureadm

# Ref: https://docs.ansible.com/ansible/2.9/reference_appendices/interpreter_discovery.html
# Silence warnings about Python interpreter discovery
export           ANSIBLE_PYTHON_INTERPRETER=auto_silent

# Ref: https://docs.ansible.com/ansible/2.9/plugins/callback/default.html
# Don't show skipped tasks
export           ANSIBLE_DISPLAY_SKIPPED_HOSTS=no

# Ref: https://docs.ansible.com/ansible/2.9/plugins/callback/profile_tasks.html
# Commented out defaults below
export           ANSIBLE_CALLBACK_WHITELIST=profile_tasks
#export          PROFILE_TASKS_TASK_OUTPUT_LIMIT=20
#export          PROFILE_TASKS_SORT_ORDER=descending

# NOTE: In the short term, keep any modifications to the above in sync with
# ../terraform/terraform-units/modules/sap_system/output_files/ansible.cfg.tmpl


# Select command prompt
PS3='Please select playbook: '

# Selectable options list; please keep the order of the initial
# playbook related entries consistent with the ordering of the
# all_playbooks array defined below
options=(
        # Specific playbook entries
        "Base OS Config"
        "SAP specific OS Config"
        "BOM Processing"
        "HANA DB Install"
        "SCS Install"
        "DB Load"
        "PAS Install"
        "APP Install"
        "WebDisp Install"
        "Pacemaker Setup"
        "Pacemaker SCS Setup"
        "Pacemaker HANA Setup"

        # Special menu entries
        "Install SAP (1-7)"
        "Post SAP Install (8-12)"
        "All Playbooks"
        "Quit"
)

# List of all possible playbooks
all_playbooks=(
        # Basic/Minimal SAP Install Steps
        ${cmd_dir}/playbook_01_os_base_config.yaml
        ${cmd_dir}/playbook_02_os_sap_specific_config.yaml
        ${cmd_dir}/playbook_03_bom_processing.yaml
        ${cmd_dir}/playbook_04_00_00_hana_db_install.yaml
        ${cmd_dir}/playbook_05_00_00_sap_scs_install.yaml
        ${cmd_dir}/playbook_05_01_sap_dbload.yaml
        ${cmd_dir}/playbook_05_02_sap_pas_install.yaml

        # Post SAP Install Steps
        ${cmd_dir}/playbook_05_03_sap_app_install.yaml
        ${cmd_dir}/playbook_05_04_sap_web_install.yaml
        ${cmd_dir}/playbook_06_00_00_pacemaker.yaml
        ${cmd_dir}/playbook_06_00_01_pacemaker_scs.yaml
        ${cmd_dir}/playbook_06_00_03_pacemaker_hana.yaml
)

# Set of options that will be passed to the ansible-playbook command
playbook_options=(
        --inventory-file="${sap_sid}_hosts.yaml"
        --private-key=${ANSIBLE_PRIVATE_KEY_FILE}
        --extra-vars="@${sap_params_file}"
        "${@}"
)

# List of playbooks to run through
playbooks=(
  # Retrieve the SSH key first before running remaining playbooks
  ${cmd_dir}/get-sshkey.yaml
)

select opt in "${options[@]}";
do
        echo "You selected ($REPLY) $opt"

        case $opt in
        "${options[-1]}")   # Quit
                break;;
        "${options[-2]}")   # Run through all playbooks
                playbooks+=( "${all_playbooks[@]}" );;
        "${options[-3]}")   # Run through last 5 playbooks
                playbooks+=( "${all_playbooks[@]:7:5}" );;
        "${options[-4]}")   # Run through first 7 playbooks
                playbooks+=( "${all_playbooks[@]:0:7}" );;
        *)
                # If not a numeric reply
                if ! [[ "${REPLY}" =~ ^[0-9]{1,2}$ ]]; then
                        echo "Invalid selection: Not a number!"
                        continue
                elif (( (REPLY > ${#all_playbooks[@]}) || (REPLY < 1) )); then
                        echo "Invalid selection: Must be in range of available options!"
                        continue
                fi
                playbooks+=( "${all_playbooks[$(( REPLY - 1 ))]}" );;
        esac

        # NOTE: If you set DEBUG to a non-empty value in your environment
        # the following line will cause the ansible-playbook command to be
        # echoed rather than executed.
        ${DEBUG:+echo} \
        ansible-playbook "${playbook_options[@]}" "${playbooks[@]}"

        break
done

