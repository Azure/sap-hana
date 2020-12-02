# HANA System Preparation

## Prerequisites

1. SAP Infrastructure deployed

## Process

1. Install Prerequisite RPMs installed, See [SAP Note 2886607](https://launchpad.support.sap.com/#/notes/2886607)
1. Configure recommended swapfile size (e.g. sizings outlined in [SAP note 1597355](https://launchpad.support.sap.com/#/notes/1597355)
    1. Ensure swapfile with correct sizing exists
    1. Add swapfile entry to `/etc/fstab`
    1. Ensure swap is enabled
    1. Ensure swapiness is configured
1. Create primary partion on each lun
    1. `/dev/disk/azure/scsi1/lun0`
    1. `/dev/disk/azure/scsi1/lun1`
    1. `/dev/disk/azure/scsi1/lun2`
    1. `/dev/disk/azure/scsi1/lun3`
    1. `/dev/disk/azure/scsi1/lun4`
1. Create filesystem on each lun
    1. `/dev/disk/azure/scsi1/lun0-part1`
    1. `/dev/disk/azure/scsi1/lun1-part1`
    1. `/dev/disk/azure/scsi1/lun2-part1`
    1. `/dev/disk/azure/scsi1/lun3-part1`
    1. `/dev/disk/azure/scsi1/lun4-part1`
1. Create mount points:
    1. /hana/data
    1. /hana/log
    1. /hana/shared
    1. /usr/sap
    1. /hana/backup
1. Mount filsystems to mount points

### Results and Outputs

1. HANA VM with required system configuration ready for HANA installation
