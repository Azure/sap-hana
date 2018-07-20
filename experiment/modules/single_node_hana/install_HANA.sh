#!/bin/bash

if [ "$#" -ne 9 ]; 
    then echo " Invalid parameters"
fi

# Set variables passed in
param_url_sap_sapcar=$1
param_url_sap_hostagent=$2
param_url_sap_hdbserver=$3
param_sap_sid=$4
param_sap_hostname=$5
param_sap_instancenum=$6
param_pw_os_sapadm=$7
param_pw_os_sidadm=$8
param_pw_db_system=$9

hana_path="/hana/shared/install"
# Create /hana/shared/install and move config templates
mkdir $hana_path
cd $hana_path

# Download the bits
wget -O SAPCAR_LINUX.EXE $param_url_sap_sapcar
wget -O SIGNATURE.SMF $param_url_sap_hostagent
wget -O IMDB_SERVER_LINUX.SAR $param_url_sap_hdbserver

chmod 755 ./SAPCAR_LINUX.EXE

# Extract the bits
./SAPCAR_LINUX.EXE -manifest SIGNATURE.SMF -xvf IMDB_SERVER_LINUX.SAR

# Generate the config and passwords
awk -v sap_sid="$param_sap_sid" -v sap_instancenum="$param_sap_instancenum" -v sap_hostname="$param_sap_hostname" '{gsub("<SAP_SID>", sap_sid); gsub("<SAP_HOSTNAME>", sap_hostname); gsub("<SAP_INSTANCENUM>", sap_instancenum);}1' /tmp/sid_config_template.txt > ${param_sap_sid}_configfile
temp=`awk -v pw_sapadm="$param_pw_os_sapadm" -v pw_sidadm="$param_pw_os_sidadm" -v pw_system="$param_pw_db_system" '{gsub("<PW_SAPADM>", pw_sapadm); gsub("<PW_SIDADM>", pw_sidadm); gsub("<PW_SYSTEM>", pw_system);}1' /tmp/sid_passwords_template.txt`

# Pass the configs into the HANA install
echo $temp | $hana_path/SAP_HANA_DATABASE/hdblcm --batch --action=install --configfile=${param_sap_sid}_configfile --read_password_from_stdin=xml
