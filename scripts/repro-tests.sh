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
	echo "usage: repro-tests.sh [--release RELEASE] [--target TARGET] artfacts1 artifacts2"
	echo ""
	echo " Optional arguments:"
	echo "  --release RELEASE: debian distro releases e.g. buster, bullseye, etc. (default: buster)"
	echo "  --target TARGET: e.g. qemu-amd64, qemu-arm64, qemu-arm (default: qemu-amd64)"
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

set -- $remaining_vars
artifacts1="$1"
artifacts2="$2"
if [ -z "$artifacts1" ] || [ -z "$artifacts2" ]; then
	echo "artifact folders are missing"
	usage
	exit 1
fi

# Define files in the artifacts for checking the reproducibility
set -- \
	"${IMAGE_BASE}-${RELEASE}-${TARGET}-vmlinuz" \
	"${IMAGE_BASE}-${RELEASE}-${TARGET}-vmlinux" \
	"${IMAGE_BASE}-${RELEASE}-${TARGET}-initrd.img" \
	"${IMAGE_BASE}-${RELEASE}-${TARGET}.tar.gz" \
	"linux.efi" \
	"${IMAGE_BASE}-${RELEASE}-${TARGET}.swu" \
	"${IMAGE_BASE}-${RELEASE}-${TARGET}.squashfs" \

# compare artifacts
res=0
for file in "$@"; do
	if [ -f "${artifacts1}/${file}" ] && [ -f "${artifacts1}/${file}" ]; then
		if $DIFFOSCOPE --text "${file}.diffoscope_output.txt" \
			"${artifacts1}/${file}" \
			"${artifacts2}/${file}" > /dev/null 2>&1; then
			echo "${file}: ${GREEN}Reproducible${NC}" | tee -a diffoscope_output.txt
		else
			echo "${file}: ${RED}Not-Reproducible${NC}" | tee -a diffoscope_output.txt
			res=1
		fi
	fi
done

exit $res
