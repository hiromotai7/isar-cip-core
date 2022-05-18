#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2019
#
# Authors:
#  Jan Kiszka <jan.kiszka@siemens.com>
#
# SPDX-License-Identifier: MIT
#

inherit image

ISAR_RELEASE_CMD = "git -C ${LAYERDIR_cip-core} describe --tags --dirty --always --match 'v[0-9].[0-9]*'"
DESCRIPTION = "CIP Core image"

IMAGE_INSTALL += "customizations"

CIP_IMAGE_OPTIONS ?= ""
include ${CIP_IMAGE_OPTIONS}

image_configure_fstab_append () {
    # Add /boot to /etc/fstab for fw_printenv
    echo "/dev/mmcblk0p1 /boot vfat defaults,nofail 0 0" | sudo tee -a ${IMAGE_ROOTFS}/etc/fstab
    # remove /var partition
    sudo sed -i '/LABEL=var/d' ${IMAGE_ROOTFS}/etc/fstab
    # make /dev/root as read-write
    sudo sed -i 's/defaults,ro/defaults/' ${IMAGE_ROOTFS}/etc/fstab
}
