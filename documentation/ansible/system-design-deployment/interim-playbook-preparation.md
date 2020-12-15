# Modify Existing Deployment Process

## Notes

1. Prior to following HANA Installation Template Preparation or any Deployment, there is some existing configuration which should be run. However, the existing and new processes overlap, which will break the deployment, unless the existing playbook is changed as documented below.

1. The following process assumes that the SAP System deployment has been run from the deployer, thus generating the folder: `Azure_SAP_Automated_Deployment/WORKSPACES/SAP_SYSTEM/XXXXX/ansible_config_files`, where `XXXXX` is the name of your deployment, e.g. `NP-EUS2-SAP0-X00`. The folder will contain three files

   ```text
   hosts
   hosts.yml
   output.json
   ```

   These files are used for the automated configuration via Ansible.

## Preparing the Existing Ansible Playbook

To enable the deployment to succeed, you must comment out certain lines in `Azure_SAP_Automated_Deployment/sap-hana/deploy/ansible/sap_playbook.yml`.

Log on to the deployer and comment out the following Ansible plays:

1. Azure File Share mounting, lines 49-65:

   ```yml
   # Mount Azure File share on all linux jumpboxes including rti
   - hosts: localhost:jumpboxes_linux
     become: true
     become_user: root
     roles:
       - role: mount-azure-files
         when: output.software.storage_account_sapbits.file_share_name != ""

   # Mount Azure File share on all hanadbnodes. When the scenario is Large Instance, this task will be skipped
   - hosts: hanadbnodes
     become: true
     become_user: root
     roles:
       - role: mount-azure-files
         when:
           - output.software.storage_account_sapbits.file_share_name != ""
           - hana_database.size != "LargeInstance"
   ```

1. SAP Media downloading, lines 67-81:

   ```yml
   # Download SAP Media on Azure File Share
   - hosts: localhost
     become: true
     become_user: root
     roles:
       - role: sap-media-download

   - hosts: hanadbnodes
     become: true
     become_user: root
     roles:
       - role: sap-media-transfer
         when: hana_database.size == "LargeInstance"
       - role: large-instance-environment-setup
         when: hana_database.size == "LargeInstance"
   ```

1. Hana DB components install, lines  94-142:

   ```yml
   # Hana DB components install
   - hosts: hanadbnodes
     become: true
     become_user: root
     any_errors_fatal: true
     vars_files:
       - "vars/ha-packages.yml"
     pre_tasks:
       - name: Include SAP HANA DB sizes
         include_vars:
           file: "{{ configs_path }}/hdb_sizes.json"
           name: hdb_sizes
     roles:
       - role: hdb-server-install
       - role: hana-system-replication
         when: hana_database.high_availability
         vars:
           sid: "{{ hana_database.instance.sid }}"
           instance_number: "{{ hana_database.instance.instance_number }}"
           hdb_version: "{{ hana_database.db_version }}"
           hdb_disks: "{{ hdb_sizes[hana_database.size].storage }}"
           hana_system_user_password: "{{ hana_database.credentials.db_systemdb_password }}"
           primary_instance:
             name: "{{ hana_database.nodes[0].dbname }}"
             ip_admin: "{{ hana_database.nodes[0].ip_admin_nic }}"
           secondary_instance:
             name: "{{ hana_database.nodes[1].dbname }}"
             ip_admin: "{{ hana_database.nodes[1].ip_admin_nic }}"
       - role: hana-os-clustering
         when: hana_database.high_availability
         vars:
           resource_group_name: "{{ output.infrastructure.resource_group.name }}"
           sid: "{{ hana_database.instance.sid }}"
           instance_number: "{{ hana_database.instance.instance_number }}"
           hdb_size: "{{ hana_database.size }}"
           hdb_lb_feip: "{{ hana_database.loadbalancer.frontend_ip }}"
           ha_cluster_password: "{{ hana_database.credentials.ha_cluster_password }}"
           sap_hana_fencing_agent_subscription_id: "{{ lookup('env', 'SAP_HANA_FENCING_AGENT_SUBSCRIPTION_ID') }}"
           sap_hana_fencing_agent_tenant_id: "{{ lookup('env', 'SAP_HANA_FENCING_AGENT_TENANT_ID') }}"
           sap_hana_fencing_agent_client_id: "{{ lookup('env', 'SAP_HANA_FENCING_AGENT_CLIENT_ID') }}"
           sap_hana_fencing_agent_client_password: "{{ lookup('env', 'SAP_HANA_FENCING_AGENT_CLIENT_SECRET') }}"
           primary_instance:
             name: "{{ hana_database.nodes[0].dbname }}"
             ip_admin: "{{ hana_database.nodes[0].ip_admin_nic }}"
             ip_db: "{{ hana_database.nodes[0].ip_db_nic }}"
           secondary_instance:
             name: "{{ hana_database.nodes[1].dbname }}"
             ip_admin: "{{ hana_database.nodes[1].ip_admin_nic }}"
             ip_db: "{{ hana_database.nodes[1].ip_db_nic }}"
   ```

With the above sections commented out, the Ansible to configure the servers can now be run.

1. On the deployer, change to the SAP System Ansible configuration files folder, e.g.

   ```text
   cd ~/Azure_SAP_Automated_Deployment/WORKSPACES/SAP_SYSTEM/NP-EUS2-SAP0-X00/ansible_config_files
   ```

1. Run the modified Ansible playbook:

   ```text
   ansible-playbook -i hosts.yml ~/Azure_SAP_Automated_Deployment/sap-hana/deploy/ansible/sap_playbook.yml
   ```
