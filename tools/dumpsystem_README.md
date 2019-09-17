# Documentation for dumpsystem.sh script

The dumpsystem.sh script will perform two basic functions:

1. Produce dump of system (via SuSE `supportconfig` tool) to gather system
   state.
1. Gather minimal additional information (not collected by `supportconfig`)
   to check for items that are not dumpped via `supportconfig` tool.
   
   
 The `dumpsystem.sh` script is a tool to gather what `checksystem.sh` checks
 for, but using the SuSE-supported `supportconfig` tool. The `checksystem.sh`
 script checks for the following items:
 
 - Check for stale [boot configuration files](#boot-configuration-files)
 - Check [NIC configuration](#nic-configuration)
 - Check [EDAC settings](#edac-settings)
 - Check [Swap space](#swap-space)
 
 #### Boot configuration files
 
 The `grub` utility may utilize the following files if they exist:
 
- /etc/default/grub_installdevice
- /boot/grub2/device.map

These files must not contain references to stale boot LUNs.

A copy of file `/etc/default/grub_installdevice` can be found in supportconfig
file `boot.txt`, under the following section:

```bash
#==[ Configuration File ]===========================#
# /etc/default/grub_installdevice
```

A copy of file `/boot/grub2/device.map` can be found in supportconfig
file `boot.txt`, under the following section:

```bash
#==[ Configuration File ]===========================#
# /boot/grub2/device.map
```

If either file does not exist, that's acceptable from a "system correctness"
point of view. In that case, " - File not found" is appended to the filename
in the above examples.

 #### NIC Configuration

For Revision 3 VLI systems, the system will generally contain an Intel 82599ES
Network Interface Card. This is a 10GB/second network card that is sensitive
to system configuration, and should contain the following settings:

- `"nohz=off"` should exist on the GRUB boot command line
- `"skew_tick=1"` should exist on the GRUB boot command line
- The PCI bus timeout for the NIC should be set to the maximum value (9)

Note that `checksystem.sh` uses a `dmidecode` command in order to verify
that the system is a VLI system. Output from 'dmidecode' can be found in
supportconfig file `hardware.txt`, although it's somewhat buried.

Setting of the GRUB boot command line can be found in supportconfig file
`boot.txt`, under the following section:

```bash
#==[ Configuration File ]===========================#
# /proc/cmdline
```

Finally, note that supportconfig doesn't collect PCI bus timeout information
(although supportconfig file `boot.txt` does contain file
`/etc/init.d/boot.local`, where the PCI bus timeout settings are often set).
As a result, `dumpsystem.sh` will collect this information inself as part of
it's run.

#### EDAC Settings

Both LI and VLI systems should not enable EDAC. The `checksystem.sh` script
validates this by insuring that kernel modules `edac_core` and `sb_edac` are
not loaded. This information can be found in supportconfig file 'modules.txt',
under the following section:

```bash
#==[ Command ]======================================#
# /sbin/lsmod | sort
```

Additionally, supportconfig file 'boot.txt' will show the contents of initrd
(lsinitrd /boot/initrd-$(uname -r) output), which can be checked to make sure
the edac module isn't in the initial ramdisk.

#### Swap Space

Some SuSE-generated LI images did not set up a system swap area, which
violates SAP guidelines for system configuration. This was a bug that was
rapidly fixed. To insure that the system does have a swap partition configured,
this should be validated.

An easy way to validate this is to examine file output from file
`/proc/meminfo`. This file exists in two places in supportconfig files:
 
 1. memory.txt
 2. proc.txt
 