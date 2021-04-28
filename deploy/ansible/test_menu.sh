#!/bin/bash


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



export           ANSIBLE_HOST_KEY_CHECKING=False

bash ${DEPLOYMENT_REPO_PATH}deploy/ansible/get-sshkey.sh

PS3='Please select playbook: '
options=(                           \
        "Base OS Config"            \
        "SAP specific OS Config"    \
        "BOM Processing"            \
        "HANA DB Install"           \
        "SCS Install"               \
        "DB Load"                   \
        "PAS Install"               \
        "APP Install"               \
        "WebDisp Install"           \
        "Pacemaker Setup"           \
        "Pacemaker SCS Setup"       \
        "Pacemaker HANA Setup"      \
        "Quit"                      \
)


select opt in "${options[@]}";
do
        echo "You selected ($REPLY) $opt";
        case $opt in
                "Base OS Config")           playbook=playbook_01_os_base_config.yaml;;
                "SAP specific OS Config")   playbook=playbook_02_os_sap_specific_config.yaml;;
                "BOM Processing")           playbook=playbook_03_bom_processing.yaml;;
                "HANA DB Install")          playbook=playbook_04_00_00_hana_db_install.yaml;;
                "SCS Install")              playbook=playbook_05_00_00_sap_scs_install.yaml;;
                "DB Load")                  playbook=playbook_05_01_sap_dbload.yaml;;
                "PAS Install")              playbook=playbook_05_02_sap_pas_install.yaml;;
                "APP Install")              playbook=playbook_05_03_sap_app_install.yaml;;
                "WebDisp Install")          playbook=playbook_05_04_sap_web_install.yaml;;
                "Pacemaker Setup")          playbook=playbook_06_00_00_pacemaker.yaml;;
                "Pacemaker SCS Setup")      playbook=playbook_06_00_01_pacemaker_scs.yaml;;
                "Pacemaker HANA Setup")     playbook=playbook_06_00_03_pacemaker_hana.yaml;;
                "Quit")                     break;;
        esac

# TODO:
#       1) Make SID in inventory file name a parameter.
#       2) Convert file extension to yaml.
#       3) Find more secure way to handle the ssh private key so it is not exposed.
        ansible-playbook                                                                                                \
          --inventory   X00_hosts.yaml                                                    \
          --user        azureadm                                                          \
          --private-key sshkey                                                            \
          --extra-vars="@sap-parameters.yaml"                                             \
          ~/Azure_SAP_Automated_Deployment/sap-hana/deploy/ansible/${playbook}
          break
done