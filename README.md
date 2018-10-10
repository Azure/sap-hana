SAP HANA on Azure
=================
Master Branch's status: [![Build Status](https://travis-ci.org/Azure/sap-hana.svg?branch=master)](https://travis-ci.org/Azure/sap-hana)

This repository contains terraform templates to install a single node HANA instance and HANA high-availability pair. The different pieces of infrastructure are split into modules.

1. Single node HANA instance:
   Terraform will need to be run from the ` deploy/vm/modules/single_node_hana` directory. The `terraform.tfvars` files with the required configuration needs to be put in this folder. An example tfvars file can be found below. 

2. HANA high-availability pair:
   To create the infrastructure for the HA pair, terraform will be run from the `deploy/vm/modules/ha_pair` directory.  This will allow us to have new modules for each configuration of the HANA database. Currently, both of the databases, `db0` and `db1` have HANA installed with HSR and failover capabilities. The `terraform.tfvars` files with the required configuration needs to be put in this folder. An example tfvars file can be found below.

Getting Started
-------------------------
1. Please review the [list of required SAP downloads](downloads.md) according to the scenario you want to deploy.

2. You will need to have the following installed on your machine:
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
- [Terraform](https://www.terraform.io/intro/getting-started/install.html)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#latest-releases-via-pip)

Example terraform.tfvars:
-------------------------
 az_region =  
 az_resource_group =  
 az_domain_name =  
 sap_sid =  
 db_num =  
 sap_instancenum =  
 vm_user =  
 url_cockpit =  
 url_xsa_runtime =  
 url_di_core =  
 url_sapui5 =  
 url_portal_services =  
 url_xs_services =  
 url_shine_xsa =  
 pwd_db_xsaadmin =  
 pwd_db_tenant =  
 pwd_db_shine =  
 email_shine =  
 url_sap_sapcar =  
 url_sap_hostagent =  
 url_sap_hdbserver   =  
 sshkey_path_private =  
 sshkey_path_public =  
 pw_hacluster =  
 pw_os_sapadm =  
 pw_os_sidadm =  
 pw_db_system =  
 useHana2 =  
 install_xsa =  

