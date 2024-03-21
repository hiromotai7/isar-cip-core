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
	echo "usage: repro-tests.sh [--release RELEASE] [--target TARGET] [--artifact_type ARTIFACT_TYPE] artfacts1 artifacts2"
	echo ""
	echo " Optional arguments:"
	echo "  --release RELEASE: debian distro releases e.g. buster, bullseye, etc. (default: buster)"
	echo "  --target TARGET: e.g. qemu-amd64, qemu-arm64, qemu-arm (default: qemu-amd64)"
	echo "  --artifact_type ARTIFACT_TYPE: can be either 'wic-partitions' or 'swu' to selectively run diffoscope on either wic-partitons or swu files"
	echo ""
	echo " Mandatory arguments:"
	echo "  artifacts1 and artifacts2 paths to test the artifacts reproducibility"
	echo ""
}

RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
IMAGE_BASE="cip-core-image-cip-core"
RELEASE="bullseye"
TARGET="qemu-amd64"
EXTENSION=""
DIFFOSCOPE="diffoscope"
ARTIFACT_TYPE=""

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
		--artifact_type )
			ARTIFACT_TYPE="$2"
			shift 2
			;;
		* )
			remaining_vars="$remaining_vars $1"
			shift
			;;
	esac
done

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

# Define files in the artifacts for checking the reproducibility
swu_files="${IMAGE_BASE}-${RELEASE}-${TARGET}.swu"
wic_partition_files="
	${IMAGE_BASE}-${RELEASE}-${TARGET}.wic.p0
	${IMAGE_BASE}-${RELEASE}-${TARGET}.wic.p1
	${IMAGE_BASE}-${RELEASE}-${TARGET}.wic.p2
	${IMAGE_BASE}-${RELEASE}-${TARGET}.wic.p3
	${IMAGE_BASE}-${RELEASE}-${TARGET}.wic.p4
	${IMAGE_BASE}-${RELEASE}-${TARGET}.wic.p5
	${IMAGE_BASE}-${RELEASE}-${TARGET}.wic.p6
	${IMAGE_BASE}-${RELEASE}-${TARGET}.wic.p7
"
set -- $swu_files $wic_partition_files

if [ "${ARTIFACT_TYPE}" = "wic-partitions" ]; then
	set -- $wic_partition_files
elif [ "${ARTIFACT_TYPE}" = "swu" ]; then
	set -- $swu_files
fi

# compare artifacts
res=0
for file in "$@"; do
	if [ -f "${artifacts1}/${file}" ] && [ -f "${artifacts2}/${file}" ]; then
		label=$(blkid -s LABEL -o value ${artifacts1}/${file} || true)
		fstype=$(blkid -s TYPE -o value ${artifacts1}/${file} || true)
		if $DIFFOSCOPE --text "${file}.diffoscope_output.txt" \
			--html-dir diffoscope_output \
			--html "${file}.diffoscope_output.html" \
			"${artifacts1}/${file}" \
			"${artifacts2}/${file}" > /dev/null 2>&1; then
			echo "${file}($label,$fstype): ${GREEN}Reproducible${NC}" | tee -a diffoscope_output.txt
		else
			echo "${file}($label,$fstype): ${RED}Not-Reproducible${NC}" | tee -a diffoscope_output.txt
			res=1
		fi
	fi
done

exit $res
