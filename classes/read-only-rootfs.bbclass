#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2020-2025
#
# Authors:
#  Quirin Gylstorff <quirin.gylstorff@siemens.com>
#
# SPDX-License-Identifier: MIT
#

INITRAMFS_RECIPE ?= "cip-core-initramfs"
INITRD_IMAGE = "${INITRAMFS_RECIPE}-${DISTRO}-${MACHINE}.initrd.img"

do_image_wic[depends] += "${INITRAMFS_RECIPE}:do_build"

IMAGE_INSTALL += "home-fs"

IMAGE_INSTALL:append:buster   = " tmp-fs"
IMAGE_INSTALL:append:bullseye = " tmp-fs"
IMAGE_INSTALL:append:bookworm = " tmp-fs"

# For pre bookworm images, empty /var is not usable
IMAGE_INSTALL:append = " immutable-rootfs"
IMAGE_INSTALL:remove:buster = " immutable-rootfs"
IMAGE_INSTALL:remove:bullseye = " immutable-rootfs"

ROOTFS_POSTPROCESS_COMMAND:append =" copy_dpkg_state"
ROOTFS_POSTPROCESS_COMMAND:remove:buster =" copy_dpkg_state"
ROOTFS_POSTPROCESS_COMMAND:remove:bullseye =" copy_dpkg_state"

IMMUTABLE_DATA_DIR ??= "usr/share/immutable-data"
copy_dpkg_state() {
    IMMUTABLE_VAR_LIB="${ROOTFSDIR}/${IMMUTABLE_DATA_DIR}/var/lib"
    sudo mkdir -p "$IMMUTABLE_VAR_LIB"
    sudo cp -a ${ROOTFSDIR}/var/lib/dpkg "$IMMUTABLE_VAR_LIB/"
}

RO_ROOTFS_EXCLUDE_DIRS ??= ""
EROFS_EXCLUDE_DIRS = "${RO_ROOTFS_EXCLUDE_DIRS}"
SQUASHFS_EXCLUDE_DIRS = "${RO_ROOTFS_EXCLUDE_DIRS}"

image_configure_fstab() {
    sudo tee '${IMAGE_ROOTFS}/etc/fstab' << EOF
# Begin /etc/fstab
/dev/root	/		auto		defaults,ro			0	0
LABEL=var	/var		auto		defaults			0	0
proc		/proc		proc		nosuid,noexec,nodev		0	0
sysfs		/sys		sysfs		nosuid,noexec,nodev		0	0
devpts		/dev/pts	devpts		gid=5,mode=620			0	0
tmpfs		/run		tmpfs		nodev,nosuid,size=500M,mode=755	0	0
devtmpfs	/dev		devtmpfs	mode=0755,nosuid		0	0
# End /etc/fstab
EOF
}

