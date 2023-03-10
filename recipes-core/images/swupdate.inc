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

inherit image_uuid
inherit read-only-rootfs

IMAGE_PREINSTALL:append:sid = " swupdate"
IMAGE_PREINSTALL:append:bookworm = " swupdate"
IMAGE_INSTALL:append:bullseye = " swupdate"
IMAGE_INSTALL:append:buster = " swupdate"

IMAGE_INSTALL += " swupdate-handler-roundrobin"
