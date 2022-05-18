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

inherit swupdate
inherit read-only-rootfs

ROOTFS_PARTITION_NAME = "${IMAGE_FULLNAME}.wic.p4.gz"

EXTRACT_PARTITIONS = "img4"
ROOTFS_PARTITION_NAME = "${IMAGE_FULLNAME}.wic.p2.gz"

SRC_URI += "file://sw-description.tmpl"
TEMPLATE_FILES += "sw-description.tmpl"
TEMPLATE_VARS += "PN ROOTFS_PARTITION_NAME KERNEL_IMAGE INITRD_IMAGE"

SWU_ADDITIONAL_FILES += "${ROOTFS_PARTITION_NAME}"

