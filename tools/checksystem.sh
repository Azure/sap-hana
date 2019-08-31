#!/bin/bash

# Set global exit code
EXIT_STATUS=0

# Boot configuration files
BOOT_INSTALLDEVICE_FILENAME="/etc/default/grub_installdevice"
BOOT_DEVICEMAP_FILENAME="/boot/grub2/device.map"

checkBootConfig()
{
  # Note: Handling of these files are tricky, as it's not clear when the files exist.
  #
  # 1. We know that if the files don't exist in SP3, we can upgrade to SP4
  #    without issue. But we can't depend on this without further testing,
  # 2. The files do exist in Operations-generated images,
  # 3. The files do exist in SuSE-generated SP3 images,
  # 4. The files do NOT exist in SuSE-generated SP4 images.
  #
  # We're reaching out to SuSE support to more fully understand when the
  # files are (or are not) created, and if deleting them is advised for
  # mitigation.

  # Check if boot configuration files exist
  if [ ! -e ${BOOT_INSTALLDEVICE_FILENAME} ] || [ ! -e ${BOOT_DEVICEMAP_FILENAME} ]; then
    echo "Note: Boot configuration files don't exist; skipping boot checks" 1>&2
    return
  fi

  # Get the boot LUN
  BOOT_LUN=$(blkid | grep /dev/mapper | head -1 | cut -f1 -d: | cut -f1 -d- )

  # Check /etc/default/grub_installdevice
  BOOT_INSTALLDEVICE=$(head -1 < ${BOOT_INSTALLDEVICE_FILENAME})
  if [ "${BOOT_INSTALLDEVICE}" != "${BOOT_LUN}" ]; then
    echo "ERROR: File ${BOOT_INSTALLDEVICE_FILENAME} is not configured with correct boot LUN" 1>&2
    EXIT_STATUS=1
  fi

  # Check /boot/grub2/device.map
  INSTALLDEVICE=$(awk '{print $2}' ${BOOT_DEVICEMAP_FILENAME})
  if [ "${INSTALLDEVICE}" != "${BOOT_LUN}" ]; then
    echo "ERROR: File ${BOOT_DEVICEMAP_FILENAME} is not configured with correct boot LUN" 1>&2
    EXIT_STATUS=1
  fi

  return
}

checkNicConfig()
{
  # Verify that flags are properly set to avoid port flapping on VLI systems

  # If this isn't a HPE VLI system, then there are no NIC flags to be concerned of
  #   Note that product name can be one of: UV300, HPE, or "HPE Integrity MC990 X Server"
  PRODUCT_NAME=$(dmidecode -s system-product-name)
  if [ "${PRODUCT_NAME}" != "UV300" ] && [ "${PRODUCT_NAME}" != "HPE" ] && [[ ! "${PRODUCT_NAME}" =~ "MC990 X" ]]; then
    echo "Note: System is not a VLI system - skipping NIC checks"
    return
  fi

  # Check kernel boot command line parameters

  if ! grep -q "nohz=off" /proc/cmdline; then
    echo "ERROR VLI NIC configuration: \"nohz=off\" not specified on boot command line" 1>&2
    EXIT_STATUS=1
  fi

  if ! grep -q "skew_tick=1" /proc/cmdline; then
    echo "ERROR VLI NIC configuration: \"skew_tick=1\" not specified on boot command line" 1>&2
    EXIT_STATUS=1
  fi

  # Check PCI bus timeouts

  NIC_DEVICE="82599ES"
  for i in $(lspci | grep $NIC_DEVICE | awk '{ print $1}'); do
    TIMEOUT=$(setpci -s "$i" 0xC8.w)
    if [ "${TIMEOUT}" -ne 9 ]; then
      echo "ERROR VLI NIC configuraiton: Device ${i} has PCI bus timeout of ${TIMEOUT}" 1>&2
      EXIT_STATUS=1
    fi
  done

  return
}

checkEdacDisabled()
{
  # EDAC modules are comprised of Kernel modules "sb_edac" and "edac_core".
  # Ensure that neither of these modules are currently loaded as modules.

  if lsmod | grep -q sb_edac; then
    echo "ERROR: EDAC enabled! Module sb_edac is loaded as kernel module" 1>&2
    EXIT_STATUS=1
  fi

  if lsmod | grep -q edac_core; then
    echo "ERROR: EDAC enabled! Module edac_core is loaded as kernel module" 1>&2
    EXIT_STATUS=1
  fi

  return
}

checkSwapSpace()
{
  # Get total swap space on the system
  SWAP_TOTAL=$(grep SwapTotal /proc/meminfo | awk '{ print $2 }')

  # Error determining swap space?
  if [ -z "${SWAP_TOTAL}" ]; then
    echo "ERROR: Unable to look up swap space on system" 1>&2
    EXIT_STATUS=1
    return
  fi

  # Is swap space allocated zero?
  if [ "${SWAP_TOTAL}" -eq 0 ]; then
    echo "ERROR: No swap space allocated on system! This must be corrected!" 1>&2
    EXIT_STATUS=1
  fi

  return
}

usage()
{
  echo "usage: $1 [OPTIONS]"
  echo "Options:"
  echo "  --bootfiles dir   Check for boot files in specified dir for test purposes"
  echo "  -h, --help        shows this usage text."
}

# Command line processing

COMMAND_SCRIPT=$(basename "$0")

while [ $# -ne 0 ]
do
  case "$1" in
    --bootfiles)
      BOOTFILE_DIR=$2

      if [ ! -d "${BOOTFILE_DIR}" ]; then
        echo "Specified boot file directory does not exist" >&2
        exit 2
      fi

      BOOT_INSTALLDEVICE_FILENAME=${BOOTFILE_DIR}/$(basename ${BOOT_INSTALLDEVICE_FILENAME})
      BOOT_DEVICEMAP_FILENAME=${BOOTFILE_DIR}/$(basename ${BOOT_DEVICEMAP_FILENAME})

      shift 2
      ;;

    -h | --help)
      usage "${COMMAND_SCRIPT}" >&2
      exit 0
      ;;

    *)
      echo "Invalid option, try: ${COMMAND_SCRIPT} -h" >& 2
      exit 1
      ;;
    esac
done

checkBootConfig
checkNicConfig
checkEdacDisabled
checkSwapSpace

if [ ${EXIT_STATUS} -ne 0 ]; then
  echo 1>&2
  echo "ERROR: Your system is not configured properly!" 1>&2
  echo "ERROR: Please contact Microsoft Support to resolve issues found" 1>&2
fi

exit ${EXIT_STATUS}
