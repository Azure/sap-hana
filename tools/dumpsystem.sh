#!/bin/bash

# Generate name for supportconfig file

DUMP_DIR=$(mktemp -d -t "dumpsystem-XXXXX")
OUTPUT_FILE="${DUMP_DIR}/dumpsystem.log"

# Run supportconfig, save output to our temporary directory

supportconfig -t "${DUMP_DIR}"

# We can't get PCI bus timeout information, so dump that with supportconfig

PRODUCT_NAME=$(dmidecode -s system-product-name)
echo "Machine Product Name: \"${PRODUCT_NAME}\"" >> "${OUTPUT_FILE}"
echo >> "${OUTPUT_FILE}"

# Get PCI bus timeouts

NIC_DEVICE="82599ES"
for i in $(lspci | grep "${NIC_DEVICE}" | awk '{ print $1}'); do
  TIMEOUT=$(setpci -s "$i" 0xC8.w)
  echo "NIC Device Name: ${NIC_DEVICE}, ID: ${i}, Timeout: ${TIMEOUT}" >> "${OUTPUT_FILE}"
done

# Make a compressed tar file for resulting directory

OUTPUT_TAR_FILE="${DUMP_DIR}.tar.gz"
tar -czf "${OUTPUT_TAR_FILE}" --directory "${DUMP_DIR}" "."
rm -r "${DUMP_DIR:?}/"

echo "Output file written to: ${OUTPUT_TAR_FILE}"

exit 0
