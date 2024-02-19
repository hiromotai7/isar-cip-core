#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2020
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
IMAGE_INSTALL += "tmp-fs"

# For pre bookworm images, empty /var is not usable
IMAGE_INSTALL:append:bookworm = " immutable-rootfs"

ROOTFS_POSTPROCESS_COMMAND:append:bookworm =" copy_dpkg_state"
copy_dpkg_state() {
    IMMUTABLE_VAR_LIB="${ROOTFSDIR}/usr/share/immutable-data/var/lib"
    sudo mkdir -p "$IMMUTABLE_VAR_LIB"
    sudo cp -a ${ROOTFSDIR}/var/lib/dpkg "$IMMUTABLE_VAR_LIB/"
}

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

