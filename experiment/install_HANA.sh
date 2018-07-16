#!/bin/bash

# Set variables passed in
param_url_sap_sapcar=$1
param_url_sap_hostagent=$2
param_url_sap_hdbserver=$3
param_sap_sid=$4
sap_host_name=$5
param_sap_instancenum=$6
param_sap_sapadm=$7
param_pw_os_sidadm=$8
param_pw_db_system=$9

# Create /hana/shared/install and move config templates
mkdir /hana/shared/install
cd /hana/shared/install

# Download the bits
wget -O SAPCAR_LINUX.EXE $param_url_sap_sapcar
wget -O SIGNATURE.SMF $param_url_sap_hostagent
wget -O IMDB_SERVER_LINUX.SAR $param_url_sap_hdbserver

chmod 755 ./SAPCAR_1014-80000935.EXE

# Extract the bits
./SAPCAR_LINUX.EXE -manifest SIGNATURE.SMF -xvf IMDB_SERVER_LINUX.SAR

# Generate the config and passwords
awk -v sap_sid="$param_sap_sid" -v sap_instance_num="$param_sap_instancenum" -v sap_host_name="$sap_host_name" '{gsub("<SAP_SID>", sap_sid); gsub("<SAP_HOST_NAME>", sap_host_name); gsub("<SAP_INSTANCE_NUM>", sap_instance_num);}1' /tmp/sid_config_template.txt > ${SAP_SID}_configfile
temp=`awk -v sap_adm_pw="$param_sap_sapadm" -v sid_adm_pw="$param_sap_sidadm" -v system_pw="$param_pw_db_system" '{gsub("<SAP_ADM_PW>", sap_adm_pw); gsub("<SID_ADM_PW>", sid_adm_pw); gsub("<SYSTEM_PW>", system_pw);}1' /tmp/sid_passwords_template.txt`
# Pass the configs into the HANA install
echo $temp | /hana/shared/install/SAP_HANA_DATABASE/hdblcm --batch --action=install --configfile=${param_sap_sid}_configfile --read_password_from_stdin=xml
