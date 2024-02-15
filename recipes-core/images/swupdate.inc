#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2023
#
# Authors:
#  Quirin Gylstorff <quirin.gylstorff@siemens.com>
#
# SPDX-License-Identifier: MIT
#

inherit image_uuid
inherit read-only-rootfs

SWU_SIGNED ?= "1"

IMAGE_INSTALL += " swupdate"

IMAGE_INSTALL:remove:sid = "swupdate"
IMAGE_PREINSTALL:append:sid = " swupdate"

IMAGE_INSTALL += " swupdate-handler-roundrobin"
