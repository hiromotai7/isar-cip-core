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

WIC_HOME_PARTITION = ""
WIC_HOME_PARTITION:separate-home-part = "part /home --source rootfs --change-directory=home --fstype=ext4 --label home --align 1024  --size 1G --fsuuid 1f55d66a-40d8-11ee-be56-0242ac120002 --uuid c07d5e8f-3448-46dc-9c0f-58904f369524"

IMAGE_INSTALL += " move-homedir-var"
IMAGE_INSTALL:append:separate-home-part = " home-fs"
IMAGE_INSTALL:remove:separate-home-part = " move-homedir-var"

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

IMMUTABLE_DATA_DIR ??= "/usr/share/immutable-data"

copy_dpkg_state() {
    IMMUTABLE_VAR_LIB="${ROOTFSDIR}${IMMUTABLE_DATA_DIR}/var/lib"
    sudo mkdir -p "$IMMUTABLE_VAR_LIB"
    sudo cp -a ${ROOTFSDIR}/var/lib/dpkg "$IMMUTABLE_VAR_LIB/"
}

ROOTFS_POSTPROCESS_COMMAND:append = " copy_home_to_immutable_data"
ROOTFS_POSTPROCESS_COMMAND:remove:separate-home-part = " copy_home_to_immutable_data"
copy_home_to_immutable_data() {
    IMMUTABLE_HOME_DIR="${ROOTFSDIR}${IMMUTABLE_DATA_DIR}/"
    sudo mkdir -p "$IMMUTABLE_HOME_DIR"
    sudo mv ${ROOTFSDIR}/home "$IMMUTABLE_HOME_DIR/"
    # as the rootfs is read-only we need to create the link
    # between /var/home and /home during creation.
    sudo chroot ${IMAGE_ROOTFS} ln -s /var/home /home
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
