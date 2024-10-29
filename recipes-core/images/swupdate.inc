#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2023-2024
#
# Authors:
#  Quirin Gylstorff <quirin.gylstorff@siemens.com>
#
# SPDX-License-Identifier: MIT
#

inherit image_uuid
inherit read-only-rootfs

SWU_SIGNED ?= "1"
SWU_HW_COMPAT ?= "cip-core-1.0"
IMAGER_BUILD_DEPS:swu += "${@'swupdate-signer' if bb.utils.to_boolean(d.getVar('SWU_SIGNED')) else ''}"
IMAGER_INSTALL:swu += "${@'swupdate-signer' if bb.utils.to_boolean(d.getVar('SWU_SIGNED')) else ''}"
IMAGE_INSTALL += "${@'swupdate-certificates' if bb.utils.to_boolean(d.getVar('SWU_SIGNED')) else ''}"

SWUPDATE_SELFBUILT ?= "0"
SWUPDATE_SELFBUILT:buster = "1"
SWUPDATE_SELFBUILT:bullseye = "1"
SWUPDATE_SELFBUILT:bookworm = "1"

IMAGE_INSTALL:append = "${@' swupdate' if bb.utils.to_boolean(d.getVar('SWUPDATE_SELFBUILT')) else ''}"
IMAGE_PREINSTALL:append = "${@'' if bb.utils.to_boolean(d.getVar('SWUPDATE_SELFBUILT')) else ' swupdate'}"

IMAGE_INSTALL += " swupdate-handler-roundrobin"
