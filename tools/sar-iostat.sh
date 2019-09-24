#!/bin/bash

# Generate name for supportconfig file

DUMP_DIR="/tmp/sar-iostat"
DUMP_DIR_OLD="/tmp/sar-iostat.old"
LOCK_FILE="/tmp/sar-iostat.lock"

SAR_OUTPUT="${DUMP_DIR}/sar.data"
IOSTAT_OUTPUT="${DUMP_DIR}/iostat.log"
MPSTAT_OUTPUT="${DUMP_DIR}/mpstat.log"
TCPDUMP_OUTPUT_ETH1="${DUMP_DIR}/tcpdump-eth1.out"
TCPDUMP_OUTPUT_ETH2="${DUMP_DIR}/tcpdump-eth2.out"
TCPDUMP_OUTPUT_ETH3="${DUMP_DIR}/tcpdump-eth3.out"
TCPDUMP_OUTPUT_ETH4="${DUMP_DIR}/tcpdump-eth4.out"

LOGROTATE_CONF="${DUMP_DIR}/sar-iostat-lr.conf"

# Function definitions

function start_jobs() {
  # Start collecting our data
  # NOTE: These must be continually running, as the first report is since boot,
  #       which is not what we want

  iostat -d -k -x -y 1 > "${IOSTAT_OUTPUT}" &
  # mpstat collects averages, so pull that less often
  mpstat -I ALL 5 > "${MPSTAT_OUTPUT}" &
  sar -A -o "${SAR_OUTPUT}" 1 > /dev/null &

  /usr/sbin/tcpdump -tttt -i eth1 ether proto 0x8808 -w "${TCPDUMP_OUTPUT_ETH1}" -U 2>/dev/null &
  /usr/sbin/tcpdump -tttt -i eth2 ether proto 0x8808 -w "${TCPDUMP_OUTPUT_ETH2}" -U 2>/dev/null &
  /usr/sbin/tcpdump -tttt -i eth3 ether proto 0x8808 -w "${TCPDUMP_OUTPUT_ETH3}" -U 2>/dev/null &
  /usr/sbin/tcpdump -tttt -i eth4 ether proto 0x8808 -w "${TCPDUMP_OUTPUT_ETH4}" -U 2>/dev/null &
}

function stop_jobs() {
  # Delete the collection processes

  killall -w iostat mpstat sar tcpdump
}

function ctrl_c() {
  # Delete the collection processes and exit

  stop_jobs
  echo "Exiting due to interrupt ..."

  rm -f "${LOCK_FILE}"
  exit 0
}

(
  # Get an exclusive lock
  flock -n 9 || exit 1

  # We have an exclusive lock, so get started

  # We want to keep up to one old directory; estimates are that this
  # directory can take up to about 110MB (worst case), which isn't
  # excessive. The concern is that if the system does crash, we may
  # want the data at the time of the crash.

  if [ -e "${DUMP_DIR}" ]; then
      rm -rf "${DUMP_DIR_OLD:?}/"
      mv "${DUMP_DIR}" "${DUMP_DIR_OLD}"
  fi

  mkdir "${DUMP_DIR}"

  # Write out our logrotate configurion file

  # NOTE: We need to collect data for 5 hours; sleep time and log files to keep
  #       (in logrorate configuration) are thus tied together!
  #       Sleep of 300 seconds means we keep 12 * 5 log files ...

  cat << EOF > "${LOGROTATE_CONF}"
    "${IOSTAT_OUTPUT}" "${MPSTAT_OUTPUT}" "${SAR_OUTPUT}" {
      compress
      rotate 60
    }

    "${TCPDUMP_OUTPUT_ETH1}" "${TCPDUMP_OUTPUT_ETH2}" "${TCPDUMP_OUTPUT_ETH3}" "${TCPDUMP_OUTPUT_ETH4}" {
      compress
      notifempty
      rotate 60
    }
EOF

  # Start collecting our data

  start_jobs

  # Trap for interrupt (control-c)

  trap ctrl_c INT

  # Loop for log compression/cleanup

  for (( ; ; )); do
    # NOTE: We need to collect data for 5 hours; sleep time and log files to keep
    #       (in logrorate configuration) are thus tied together!
    #       Sleep of 300 seconds means we keep 12 * 5 log files ...
    sleep 300

    # Rotate the log files
    # To minimize chance of corruption (particularly with sar's binary output),
    # it is safest to stop collection, rotate, and start collection again

    stop_jobs > /dev/null 2>&1
    /usr/sbin/logrotate -f "${LOGROTATE_CONF}"
    start_jobs
  done

) 9>"${LOCK_FILE}"

exit 0
