#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2023-2025
#
# Authors:
#  Quirin Gylstorff <quirin.gylstorff@siemens.com>
#
# SPDX-License-Identifier: MIT
#

inherit image_uuid
inherit read-only-rootfs

# read-only rootfs with /home and /var
# as separate partitions is used
# /boot is excluded as an unified kernel image
# is used. This images are stored in separate partitions.
RO_ROOTFS_EXCLUDE_DIRS = "boot var home"

SWU_SIGNED ?= "1"
SWU_HW_COMPAT ?= "cip-core-1.0"
IMAGER_BUILD_DEPS:swu += "${@'swupdate-signer' if bb.utils.to_boolean(d.getVar('SWU_SIGNED')) else ''}"
IMAGER_INSTALL:swu += "${@'swupdate-signer' if bb.utils.to_boolean(d.getVar('SWU_SIGNED')) else ''}"
IMAGE_INSTALL += "${@'swupdate-certificates' if bb.utils.to_boolean(d.getVar('SWU_SIGNED')) else ''}"

SWUPDATE_SELFBUILT ?= "0"
SWUPDATE_SELFBUILT:buster = "1"
SWUPDATE_SELFBUILT:bullseye = "1"
SWUPDATE_SELFBUILT:bookworm = "1"

python() {
    base_distro = d.getVar('BASE_DISTRO_CODENAME')
    if base_distro not in ['buster', 'bullseye', 'bookworm'] and \
       bb.utils.to_boolean(d.getVar('SWUPDATE_SELFBUILT')):
        bb.fatal(f'Self-built SWUpdate not supported for {base_distro}')

    if not bb.utils.to_boolean(d.getVar('SWUPDATE_SELFBUILT')) and \
       not bb.utils.to_boolean(d.getVar('SWU_SIGNED')):
        bb.fatal('SWUpdate from Debian requires signed SWUs')
}

IMAGE_INSTALL:append = "${@' swupdate' if bb.utils.to_boolean(d.getVar('SWUPDATE_SELFBUILT')) else ''}"
IMAGE_PREINSTALL:append = "${@'' if bb.utils.to_boolean(d.getVar('SWUPDATE_SELFBUILT')) else ' swupdate'}"

IMAGE_INSTALL += " swupdate-handler-roundrobin"
