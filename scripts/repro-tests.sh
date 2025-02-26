#!/bin/sh
#
# CIP Core, generic profile
#
# Copyright (c) Toshiba corp., 2023
#
# Authors:
#  Venkata Pyla <venkata.pyla@toshiba-tsip.com>
#
# SPDX-License-Identifier: MIT
#

set -e

usage()
{
	echo "usage: repro-tests.sh [--release RELEASE] [--target TARGET] artifacts1 artifacts2"
	echo ""
	echo " Optional arguments:"
	echo "  --release RELEASE: debian distro releases e.g. buster, bullseye, etc. (default: bookworm)"
	echo "  --target TARGET: e.g. qemu-amd64, qemu-arm64, qemu-arm (default: qemu-amd64)"
	echo "  --extension EXTENSION: e.g. security (default: "")"
	echo ""
	echo " Mandatory arguments:"
	echo "  artifacts1 and artifacts2 paths to test the artifacts reproducibility"
	echo ""
}

RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
IMAGE_BASE="cip-core-image-cip-core"
RELEASE="bookworm"
TARGET="qemu-amd64"
EXTENSION=""
DIFFOSCOPE="diffoscope"

while [ "$1" != "" ]; do
	case $1 in
		-r | --release )
			RELEASE="$2"
			shift 2
			;;
		-t | --target )
			TARGET="$2"
			shift 2
			;;
		-e | --extension )
			EXTENSION="$2"
			shift 2
			;;
		-h | --help )
			usage
			exit
			;;
		* )
			remaining_vars="$remaining_vars $1"
			shift
			;;
	esac
done

# shellcheck disable=SC2086
set -- $remaining_vars
artifacts1="$1"
artifacts2="$2"
if [ -z "$artifacts1" ] || [ -z "$artifacts2" ]; then
	echo "artifact folders are missing"
	usage
	exit 1
fi

if [ "${EXTENSION}" = "security" ]; then
	IMAGE_BASE="cip-core-image-security-cip-core"
fi

run_diffoscope() {
    file="$1"
    artifacts1_dir="$2"
    artifacts2_dir="$3"
    label=""
    fstype=""
    res=0

    # Get partition label and filesystem type
    label=$(blkid -s LABEL -o value "${artifacts1_dir}"/"${file}" || true)
    fstype=$(blkid -s TYPE -o value "${artifacts2_dir}"/"${file}" || true)

    # Run diffoscope comparison
    if $DIFFOSCOPE --text "${file}.diffoscope_output.txt" \
        --html-dir diffoscope_output \
        --html "${file}.diffoscope_output.html" \
        "${artifacts1_dir}/${file}" \
        "${artifacts2_dir}/${file}" > /dev/null 2>&1; then
        echo "${file}($label,$fstype): ${GREEN}Reproducible${NC}" | tee -a diffoscope_output.txt
    else
        echo "${file}($label,$fstype): ${RED}Not-Reproducible${NC}" | tee -a diffoscope_output.txt
        res=1
    fi

    return $res
}

# compare swu file
res_swu=0
swu_file="${IMAGE_BASE}-${RELEASE}-${TARGET}.swu"
if [ -f "${artifacts1}/${swu_file}" ] && [ -f "${artifacts2}/${swu_file}" ]; then
	swu1_sha256sum=$(sha256sum "${artifacts1}/${IMAGE_BASE}-${RELEASE}-${TARGET}.swu" | awk '{ print $1 }')
	swu2_sha256sum=$(sha256sum "${artifacts2}/${IMAGE_BASE}-${RELEASE}-${TARGET}.swu" | awk '{ print $1 }')
	if [ "$swu1_sha256sum" != "$swu2_sha256sum" ]; then
		if ! run_diffoscope "$swu_file" "$artifacts1" "$artifacts2"; then
			res_swu=1
		fi
	else
		echo "${IMAGE_BASE}-${RELEASE}-${TARGET}.swu: ${GREEN}Reproducible${NC}" | tee -a diffoscope_output.txt
	fi
fi

# compare wic files
res_wic=0
image1_sha256sum=$(sha256sum "${artifacts1}/${IMAGE_BASE}-${RELEASE}-${TARGET}.wic" | awk '{ print $1 }')
image2_sha256sum=$(sha256sum "${artifacts2}/${IMAGE_BASE}-${RELEASE}-${TARGET}.wic" | awk '{ print $1 }')
if [ "$image1_sha256sum" != "$image2_sha256sum" ]; then
	echo "${IMAGE_BASE}-${RELEASE}-${TARGET}.wic: ${RED}Not-Reproducible${NC}"
	res_wic=1
	echo "Running diffoscope on individual partitions..."
	for part_num in $(seq 0 7); do
		part_file=${IMAGE_BASE}-${RELEASE}-${TARGET}.wic.p${part_num}
		if [ -f "${artifacts1}/${part_file}" ] && [ -f "${artifacts2}/${part_file}" ]; then
			run_diffoscope "$part_file" "$artifacts1" "$artifacts2"
		fi
	done
else
	echo "${IMAGE_BASE}-${RELEASE}-${TARGET}.wic: ${GREEN}Reproducible${NC}" | tee -a diffoscope_output.txt
fi
exit $(( res_swu || res_wic ))