#!/bin/bash

###########################################################
# Setup machine for HANA
###########################################################

sid=$1

# setup disk layout
echo "Creating physical volumes"
sudo pvcreate /dev/disk/azure/scsi1/lun0   
sudo pvcreate /dev/disk/azure/scsi1/lun1
sudo pvcreate /dev/disk/azure/scsi1/lun2

echo "Creating volume groups"
sudo vgcreate vg_hana_data_$sid /dev/disk/azure/scsi1/lun0
sudo vgcreate vg_hana_log_$sid /dev/disk/azure/scsi1/lun1
sudo vgcreate vg_hana_shared_$sid /dev/disk/azure/scsi1/lun2

echo "Creating logical volumes"
sudo lvcreate -l 100%FREE -n hana_data vg_hana_data_$sid
sudo lvcreate -l 100%FREE -n hana_log vg_hana_log_$sid
sudo lvcreate -l 100%FREE -n hana_shared vg_hana_shared_$sid

echo "Initializing file systems"
sudo mkfs.xfs /dev/vg_hana_data_$sid/hana_data
sudo mkfs.xfs /dev/vg_hana_log_$sid/hana_log
sudo mkfs.xfs /dev/vg_hana_shared_$sid/hana_shared

echo "Creating mount points"
mkdir -p /hana/data/$sid
mkdir -p /hana/log/$sid
mkdir -p /hana/shared/$sid

# Mount volumes
echo "Mounting volumes into fstab"
cat << EOF | sudo tee -a /etc/fstab
/dev/vg_hana_shared_$sid/hana_shared /hana/shared/$sid xfs  defaults,nofail  0  2
/dev/vg_hana_log_$sid/hana_log /hana/log/$sid xfs  defaults,nofail  0  2
/dev/vg_hana_data_$sid/hana_data /hana/data/$sid xfs  defaults,nofail  0  2
EOF
sudo mount -a
