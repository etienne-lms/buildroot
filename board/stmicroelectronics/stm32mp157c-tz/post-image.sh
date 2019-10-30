#!/usr/bin/env bash

GENIMAGE_CFG="$(dirname $0)/genimage.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"
echo $(GENIMAGE_TMP)
echo -- ------------------------

mkdir -p build/target-bootfs
rm -rf build/target-bootfs
cp -ar build/target/boot build/target-bootfs

genimage \
        --rootpath "${ROOTPATH_TMP}"     \
        --tmppath "${GENIMAGE_TMP}"    \
        --inputpath "${BINARIES_DIR}"  \
        --outputpath "${BINARIES_DIR}" \
        --config "${GENIMAGE_CFG}"


support/scripts/genimage.sh -c board/stmicroelectronics/stm32mp157c-tz/genimage-$1.cfg
