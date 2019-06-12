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
IMAGE_INSTALL += "swupdate"

do_wic_image_prepend () {
    # Make ${PP_DEPLOY} available to wic
    image_do_mounts
}

do_rootfs_append () {
    # Add /boot to /etc/fstab for fw_printenv
    echo "/dev/mmcblk0p1 /boot vfat defaults,nofail 0 0" | sudo tee -a ${IMAGE_ROOTFS}/etc/fstab
}
