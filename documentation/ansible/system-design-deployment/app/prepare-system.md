# App System Preparation

## Prerequisites

1. SAP Infrastructure deployed

## Process

1. Install Prerequisite RPMs installed, See [SAP Note 2886607](https://launchpad.support.sap.com/#/notes/2886607)
1. Configure recommended swapfile size (e.g. sizings outlined in [SAP note 1597355](https://launchpad.support.sap.com/#/notes/1597355)
    1. Ensure swapfile with correct sizing exists
    1. Add swapfile entry to `/etc/fstab`
    1. Ensure swap is enabled
    1. Ensure swapiness is configured
1. Create primary partition on `/dev/disk/azure/scsi1/lun0`
1. Create filesystem on lun0 `/dev/disk/azure/scsi1/lun0-part1`
1. Create mount point `/usr/sap`
1. Mount filsystems to mount points `mount /dev/disk/azure/scsi1/lun0-part1 /usr/sap`

### Results and Outputs

1. Application VMs with required system configuration ready for application installation
