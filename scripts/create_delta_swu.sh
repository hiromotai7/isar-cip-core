#!/bin/bash
#
# CIP Core, generic profile
#
# Copyright (c) Toshiba corp., 2024
#
# Authors:
#  Adithya Balakumar <adithya.balakumar@toshiba-tsip.com>
#
# SPDX-License-Identifier: MIT
#

set -e

ABROOTFS_PART_UUID_A=fedcba98-7654-3210-cafe-5e0710000001
ABROOTFS_PART_UUID_B=fedcba98-7654-3210-cafe-5e0710000002
SWU_KERNEL=linux.efi
SWU_ROOT_DEVICE="C:BOOT0:$SWU_KERNEL->$ABROOTFS_PART_UUID_A,C:BOOT1:$SWU_KERNEL->$ABROOTFS_PART_UUID_B"
SWU_KERNEL_DEVICE="C:BOOT0:$SWU_KERNEL->BOOT0,C:BOOT1:$SWU_KERNEL->BOOT1"
DISTRO="bookworm"
IMAGE_BASE="cip-core-image-cip-core"
TARGET="qemu-amd64"

usage()
{
	echo "usage: create_delta_swu.sh [--distro DISTRO] --type DELTA_TYPE artfacts1 artifacts2"
	echo ""
	echo " Mandatory arguments:"
	echo "  --type DELTA_TYPE: rdiff or zchunk"
	echo "  --url : If delta update type is zchunk, pass zchunk file url"
	echo "  artifacts1 and artifacts2 paths"
	echo ""
	echo " Optional arguments:"
	echo "  --distro DISTRO: debian distro releases (default: bookworm)"
	echo "  --target TARGET: e.g. qemu-amd64, qemu-arm64, qemu-arm (default: qemu-amd64)"
	echo ""
}

while [ "$1" != "" ]; do
	case $1 in
		--type )
			DELTA_TYPE="$2"
			shift 2
			;;
		--url )
			ZCHUNK_FILE_URL="$2"
			shift 2
			;;
		--help )
			usage
			exit
			;;
		--distro )
			DISTRO="$2"
			shift 2
			;;
		--extension )
			EXTENSION="$2"
			shift 2
			;;
		--target )
			TARGET="$2"
			shift 2
			;;
		* )
			remaining_vars="$remaining_vars $1"
			shift
			;;
	esac
done

set -- $remaining_vars
ARTIFACTS1_DIR="$1"
ARTIFACTS2_DIR="$2"
if [ -z "$ARTIFACTS1_DIR" ] || [ -z "$ARTIFACTS2_DIR" ]; then
	echo "artifact folders are missing"
	usage
	exit 1
fi

if [ "$DELTA_TYPE" != "rdiff" ] && [ "$DELTA_TYPE" != "zchunk" ]; then
	echo "Invalid delta type parameter"
	usage 
	exit
fi

if [ "$DELTA_TYPE" == "zchunk" ] && [ -z "$ZCHUNK_FILE_URL" ]; then
	echo "zchunk file URL is mandatory if delta type is zchunk"
	usage
	exit
fi

if [ "${EXTENSION}" = "security" ]; then
	IMAGE_BASE="cip-core-image-security-cip-core"
fi

echo "Delta type: $DELTA_TYPE"
echo "Distro: $DISTRO"
echo "Artifacts1: $ARTIFACTS1_DIR"
echo "Artifacts2: $ARTIFACTS2_DIR"

SWU_BEFOREIMAGE=("$ARTIFACTS1_DIR"/"${IMAGE_BASE}-${DISTRO}-${TARGET}".wic)
SWU_AFTERIMAGE=("$ARTIFACTS2_DIR"/"${IMAGE_BASE}-${DISTRO}-${TARGET}".wic)
SWU_OUTPUTDIR=delta_update_artifacts

if [ -d "$SWU_OUTPUTDIR" ]; then
        rm -r $SWU_OUTPUTDIR
fi

# create output directory
mkdir $SWU_OUTPUTDIR

if [ "$DELTA_TYPE" == "rdiff" ]; then

	SECTOR_SIZE=512
	ROOTFS_START_SECTOR_IMAGE1=$(fdisk -l -o Name,Start "$ARTIFACTS1_DIR"/*.wic | awk -v name=primary '$0 ~ name {print $2}' | head -n 1)
	DD_SKIP_IMAGE1=$((($ROOTFS_START_SECTOR_IMAGE1 * $SECTOR_SIZE) / (1024 * 1024)))
	echo "Extracting root partition from $SWU_BEFOREIMAGE as before.raw"
	dd if="$SWU_BEFOREIMAGE" bs=1M skip=$DD_SKIP_IMAGE1 count=1024 of=$SWU_OUTPUTDIR/before.raw status=none
	
	ROOTFS_START_SECTOR_IMAGE2=$(fdisk -l -o Name,Start "$ARTIFACTS2_DIR"/*.wic | awk -v name=primary '$0 ~ name {print $2}' | head -n 1)
	DD_SKIP_IMAGE2=$((($ROOTFS_START_SECTOR_IMAGE2 * $SECTOR_SIZE) / (1024 * 1024)))
	echo "Extracting root partition from $SWU_AFTERIMAGE as after.raw"
	dd if="$SWU_AFTERIMAGE" bs=1M skip=$DD_SKIP_IMAGE2 count=1024 of=$SWU_OUTPUTDIR/after.raw status=none

	pushd $SWU_OUTPUTDIR > /dev/null
	echo "Creating update.delta"
	
	#create delta update using rdiff
	rdiff signature before.raw before.sig
	rdiff delta before.sig after.raw update.delta

	echo "Compressing delta"
        gzip update.delta

	FILES="sw-description sw-description.sig"

        ROOT_PARTITION_SHA256=$(sha256sum update.delta.gz | cut -d' ' -f1)
tee -a sw-description > /dev/null <<EOT
software =
{
	version = "0.2";
      	name = "cip software update";
EOT

tee -a sw-description > /dev/null <<EOT
        images: ({
        	filename = "update.delta.gz";
                device = "$SWU_ROOT_DEVICE";
                type = "roundrobin";
                compressed = "zlib";
                sha256 = "$ROOT_PARTITION_SHA256";
                properties: {
                	subtype = "image";
                        chainhandler = "rdiff_image";
                	};
                });
EOT

        FILES="$FILES update.delta.gz"
        popd > /dev/null
fi

if [ "$DELTA_TYPE" == "zchunk" ]; then
	
	SECTOR_SIZE=512
	ROOTFS_START_SECTOR_IMAGE2=$(fdisk -l -o Name,Start "$ARTIFACTS2_DIR"/*.wic | awk -v name=primary '$0 ~ name {print $2}' | head -n 1)
        DD_SKIP_IMAGE2=$((($ROOTFS_START_SECTOR_IMAGE2 * $SECTOR_SIZE) / (1024 * 1024)))
        echo "Extracting root partition from $SWU_AFTERIMAGE as after.raw"
        dd if="$SWU_AFTERIMAGE" bs=1M skip=$DD_SKIP_IMAGE2 count=1024 of=$SWU_OUTPUTDIR/after.raw status=none

	pushd $SWU_OUTPUTDIR > /dev/null
	echo "Creating .zck file"
	#create delta update using zchunk
	zck --output update.delta.zck -u --chunk-hash-type sha256 after.raw

	# Determine the size of the ZCK header
	HSIZE=$(zck_read_header -v update.delta.zck | grep "Header size" | cut -d ':' -f 2)

	# Extract just the header (we'll include this in the swu package)
	dd if=update.delta.zck of=update.delta.zck.header bs=1 count=$((HSIZE)) status=none
	
	FILES="sw-description sw-description.sig"

	ROOT_PARTITION_SHA256=$(sha256sum update.delta.zck.header | cut -d' ' -f1)
tee -a sw-description > /dev/null <<EOT
software =
{
    	version = "0.2";
    	name = "cip software update";
EOT

tee -a sw-description > /dev/null <<EOT
	images: ({
        	filename = "update.delta.zck.header";
        	device = "$SWU_ROOT_DEVICE";
       		type = "roundrobin";
        	sha256 = "$ROOT_PARTITION_SHA256";
        	properties: {
            		url = "$ZCHUNK_FILE_URL";
            		subtype = "image";
            		chainhandler = "delta";
            		zckloglevel = "error";
        		};
    		});
EOT

	FILES="$FILES update.delta.zck.header"
	popd > /dev/null

fi

# Adding kernel to the sw-description
cp "$ARTIFACTS2_DIR"/$SWU_KERNEL $SWU_OUTPUTDIR/
pushd $SWU_OUTPUTDIR > /dev/null
FILE_NAME="$SWU_KERNEL"
KERNEL_SHA256=$(sha256sum $SWU_KERNEL | cut -d' ' -f1)
tee -a sw-description > /dev/null <<EOT
	files: ({
       		filename = "$FILE_NAME";
       		path = "$SWU_KERNEL";
       		type = "roundrobin";
       		device = "$SWU_KERNEL_DEVICE";
       		filesystem = "vfat";
       		sha256 = "$KERNEL_SHA256";
       		properties: {
                  	subtype = "kernel";
       			};
   		});

EOT

FILES="$FILES $SWU_KERNEL"
popd > /dev/null

# Finish the sw-description
tee -a $SWU_OUTPUTDIR/sw-description > /dev/null <<EOT
}
EOT

# Sign the sw-description
pushd $SWU_OUTPUTDIR > /dev/null

openssl cms \
	-sign -in sw-description \
	-out "sw-description.sig" \
	-signer "../../recipes-devtools/secure-boot-secrets/files/$DISTRO/PkKek-1-snakeoil.pem" \
	-inkey "../../recipes-devtools/secure-boot-secrets/files/$DISTRO/PkKek-1-snakeoil.key" \
        -outform DER -noattr -binary
popd > /dev/null

# Create the SWU
pushd $SWU_OUTPUTDIR > /dev/null
echo "Creating the swu file"
for i in $FILES; do
        echo "$i";
done | cpio -ov -H crc > update.swu
popd > /dev/null
