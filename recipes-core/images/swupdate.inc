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
IMAGE_INSTALL += " swupdate"

IMAGE_INSTALL:remove:sid = "swupdate"
IMAGE_PREINSTALL:append:sid = " swupdate"

IMAGE_INSTALL += " swupdate-handler-roundrobin"
