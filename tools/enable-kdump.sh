#!/bin/bash
# This script enables kdump on HANA Large Instances(Type 1/2)

ExitIfFailed()
{
    if [ "$1" != 0 ]; then
        echo "$2 ! Exiting !!!!"
        exit 1
    fi
}

# operating system supported by this script
supported_os=(
    "SLES"
)

# operating system versions supported by this script
supported_version=( "12-SP3"
    "12-SP4"
    "12-SP5"
    "15-SP1"
    "15-SP2"
)

# get OS name and OS version
# /etc/os-release file has this information
# in the form of key value pair so these can be
# imported in shell varible
eval $(cat /etc/os-release | sed -e s"@: @=@")

# check if the os and version is supported by this script
supported="false"
for i in "${supported_os[@]}"; do
    if [[ "$NAME" == "$i" ]]; then
        for j in "${supported_version[@]}"; do
            if [[ "$VERSION" == "$j" ]]; then
                supported="true"
                break
            fi
        done
        break
    fi
done
if [[ "$supported" == "false" ]]; then
    echo "This script does not support current OS $NAME, VERSION $VERSION. Please raise request to support this OS and Version"
    exit 1
fi

# check if the kexec-tool is enabled
rpm -q kexec-tools
ExitIfFailed $? "kxec-tools required to enable kdump, please install"

ReplaceLowHighInGrubFile()
{
    # get low and high value reported by kdumptool calibrate
    # kdumptool calibrate reports key value pair
    # so these can be imported in shell environment
    eval $(kdumptool calibrate | sed -e s"@: @=@")
    ExitIfFailed $? "Failed to run kdumptool calibrate command"

    # get system memory in TB
    mem=$(free --tera | awk 'FNR == 2 {print $2}')
    ExitIfFailed $? "Failed to get memory using free command"

    # high memory to use for kdump is calculated according to system
    # if the total memory of a system is greater than 1TB
    # then the high value to use is (High From kdumptool * RAM in TB + LUNS / 2)
    high_to_use=$High
    if [ $mem -gt 1 ]; then
        high_to_use=$(($High*$mem))
    fi

    # Add LUNS/2 to high_to_use
    high_to_use=$(($high_to_use + $(($(lsblk | grep disk | wc -l)/2))))

    # replace high and low value in /boot/grub2/grub.cfg
    sed -i "s/crashkernel=[0-9]*[MG],high/crashkernel=$high_to_use\M,high/gI" /boot/grub2/grub.cfg
    ExitIfFailed $? "Enable to change kernel crash high value in /boot/grub2/grub.cfg"

    sed -i "s/crashkernel=[0-9]*[MG],low/crashkernel=$Low\M,low/gI" /boot/grub2/grub.cfg
    # in some OS low value for crashkernel is not present so don't exit script if not found
}

# there can be 4 cases for crashkernel parameter in /pro/cmdline
# Case 1: extended kernel parameter for crashkernel
# Case 2: crashkernel parameter specify using high, low value
# Case 3: crashkernel parameter specify using only high value
# Case 4: crashkernel entry does not exist

# in Case 1 parameter can be used at it is.
# in Case 2, 3 high, low and high can be replaced with suitable value respectively
# in case 4 this script does support enabling a kdump value.
grep "crashkernel=16G-4096G:512M,4096G-16384G:1G,16384G-32768G:2G,32768G-:3G@4G" /proc/cmdline
if [[ "$?" == "1" ]]; then # can be case 2,3,4
    # if the high value is specified in /proc/cmdline then the status of below
    # command will be not be 1
    egrep "crashkernel=[0-9]{1,}[MG],high" /proc/cmdline
    if [[ "$?" == "1" ]]; then # case 4
        echo "Missing crashkernel parameter in /proc/cmdline, Existing!!"
        exit 1
    fi

    # case 2,3
    ReplaceLowHighInGrubFile
fi

# set KDUMP_SAVEDIR in /etc/sysconfig/kdump
sed -i "s/^KDUMP_SAVEDIR=\".*\"/KDUMP_SAVEDIR=\"\/var\/crash\"/gI" /etc/sysconfig/kdump

# set KDUMP_DUMPLEVEL to 31(recommended)
sed -i "s/^KDUMP_DUMPLEVEL=[0-9]*/KDUMP_DUMPLEVEL=31/gI" /etc/sysconfig/kdump

# enable kdump service
systemctl enable kdump
ExitIfFailed $? "Failed to enable kdump service"

# set kernel.sysrq to 184(recommended)
sysctl kernel.sysrq=184
ExitIfFailed $? "Failed to set kernel.sysrq value to 184"

# load the new kernel.sysrq
sysctl -p
ExitIfFailed $? "Failed to load new kernel.sysrq value"

echo "KDUMP is successfully enabled, please reboot the system to apply the change"
exit 0