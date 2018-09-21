SAP HANA on Azure
=================

This repository contains terraform templates to install a single node HANA instance and HANA high-availability pair. The different pieces of infrastructure are split into modules.

1. Single node HANA instance:
   Terraform will need to be run from the ` deploy/vm/modules/single_node_hana` directory. The `terraform.tfvars` files with the required configuration needs to be put in this folder. An example tfvars file can be found below. 

2. HANA high-availability pair:
   To create the infrastructure for the HA pair, terraform will be run from the `deploy/vm/modules/ha_pair` directory.  This will allow us to have new modules for each configuration of the HANA database. Currently, both of the databases, `db0` and `db1` have HANA installed. The `terraform.tfvars` files with the required configuration needs to be put in this folder. An example tfvars file can be found below.

Example terraform.tfvars:
-------------------------

#Example tfvars file
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
useHana2     =
install_xsa =
