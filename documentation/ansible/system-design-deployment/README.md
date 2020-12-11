# SAP System Design and Deployment

This document outlines a process that enables a SAP Basis System Administrator to produce repeatable baseline [SAP system landscapes](https://help.sap.com/doc/saphelp_afs64/6.4/en-US/de/6b0d84f34d11d3a6510000e835363f/content.htm) running in Azure.
The repeatability applies both across different SAP products _and_ over time, as new SAP software versions are released.
For example, an administrator may have a requirement to deploy a consistent [3-tier system landscape](https://help.sap.com/doc/saphelp_afs64/6.4/en-US/de/6b0da2f34d11d3a6510000e835363f/content.htm?no_cache=true) for S/4HANA 1909 SPS02 over the course of a few months, where Production is not required until 2-3 months after the Development system is required.
This can be a challenge when SAP removes available software versions, or a customer’s technical SAP personnel changes over time.

The process is aimed at users with some prior experience of both deploying SAP systems and with the Azure cloud platform.
For example, users should be familiar with: _SAP Launchpad_, _SAP Maintenance Planner_, _SAP Download Manager_, and _Azure Portal_.

The process is split between SAP HANA and SAP Application to promote modularity and reuse in the overall SAP journey.
The SAP HANA Database deployment materials obtained by following the SAP HANA process is likely to be reused by more than one SAP Application deployment - both for different versions of the same product, and different products.

In turn, these two processes both consist of 3 distinct phases:

1. **_Acquisition_** of the SAP installation media, configuration files and tools;
1. **_Preparation_** of the SAP media library, and generation of the _Bill of Materials_ (BoM);
1. **_Deployment_** of the SAP landscape into Azure.

**Notes:**

- To prevent unecessary duplication with the Acquisition phase, the installation media and tools for all systems are stored in a single flat directory.
- To keep the SAP Application and SAP HANA proccesses modular, the SAP Application BoM contains a (nested) reference to a SAP HANA BoM, allowing them to be updated and used independently.

Two other phases are involved in the overall end-to-end lifecycle, but these are described elsewhere:

- **_Bootstrapping_** to deploy and configure the SAP Deployer and the SAP Library must be completed before _Preparation_;
- **_Provisioning_** to deploy the SAP target VMs into Azure must be completed before _Deployment_.

## Process Index

### Existing Ansible Configuration

Prior to following any documentation below there is some existing configuration which should be run, however there is some overlap with it and the process documented below.

The below assumes that the SAP System deployment has been run from the deployer, thus generating the folder: `Azure_SAP_Automated_Deployment/WORKSPACES/SAP_SYSTEM/XXXXX/ansible_config_files`

Where `XXXXX` is the name of your deployment, e.g. `NP-EUS2-SAP0-X00`.  The folder will contain three files

```text
hosts
hosts.yml
outout.json
```

These files are used for the automated configuration via Ansible.

#### Preparing the Existing Ansible Configuration

To prevent the overlap, you must log on to the deployer and comment certain lines in `Azure_SAP_Automated_Deployment/sap-hana/deploy/ansible/sap_playbook.yml`.

The following Ansible plays need to be commented out to stop the tasks from running:

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

With the above two sections commented out, the Ansible to configure the servers can now be run.

On the deployer, change to the SAP System Ansile configuration files folder, e.g.

```shell
cd ~/Azure_SAP_Automated_Deployment/WORKSPACES/SAP_SYSTEM/NP-EUS2-SAP0-X00/ansible_config_files
```

Run the Ansible playbook:

```shell
ansible-playbook -i hosts.yml ~/Azure_SAP_Automated_Deployment/sap-hana/deploy/ansible/sap_playbook.yml
```

### Database

#### SAP HANA

1. **Acquisition**
   1. [Acquire Media](./hana/acquire-media.md)
1. **Preparation**
   1. [Prepare Media](./hana/prepare-sap-library.md)
   1. [Prepare Bill of Materials](./hana/prepare-bom.md)
   1. [Validate the BoM](./bom-validation.md)
   1. [Prepare Installation Template](./hana/prepare-ini.md)
1. **Deployment**
   1. [Deploy SAP HANA SID](./hana/deploy-sid.md)

### SAP Application

1. **Prepare System**:
   1. [Prepare System](./app/prepare-system.md)
1. **Acquisition**
   1. [Acquire Media](./app/acquire-media.md)
1. **Preparation**
   1. [Prepare Media](./app/prepare-sap-library.md)
   1. [Prepare Bill of Materials](./app/prepare-bom.md)
   1. [Validate the BoM](./bom-validation.md)
   1. [Prepare Installation Template](./app/prepare-ini.md)
1. **Deployment**
   1. [Deploy SAP Application SID](./app/deploy-sid.md)
