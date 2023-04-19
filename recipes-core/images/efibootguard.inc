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

IMAGE_INSTALL:append = " efibootguard"
IMAGE_PREINSTALL:append:sid = " efibootguard"
IMAGE_PREINSTALL:append:bookworm = " efibootguard"
IMAGE_INSTALL:append:bullseye = " efibootguard"
IMAGE_INSTALL:append:buster = " efibootguard"

WIC_IMAGER_INSTALL:append = " efibootguard:${DISTRO_ARCH}"
WDOG_TIMEOUT ?= "60"
WICVARS += "WDOG_TIMEOUT KERNEL_IMAGE INITRD_IMAGE DTB_FILES"
IMAGE_FSTYPES:append = " wic"
