Placeholder for bare metal system tools

checksystem.sh: Ensures that the bare metal (LI or VLI) system is free
  of common deployment errors.

collect-logs.sh: Save tcpdump files if an event occurred within a
  system log file (such as /var/log/messages). Written to be able to be
  easily modified for various purposes. If no events occurred, then
  delete the tcpdump file as it has no useful data.

dumpsystem.sh: Produces dumps of the bare metal (LI or VLI) system to
  validate that it is free of common deployment errors.

sar-iostat.sh: Collect statistics from sar and iostat, control overall
  disk space utilized.

enable-kdump.sh: Enables kdump on a HANA Large Instances(Type 1/2).