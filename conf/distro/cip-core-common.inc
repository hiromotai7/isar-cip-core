#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2019-2023
#
# Authors:
#  Jan Kiszka <jan.kiszka@siemens.com>
#
# SPDX-License-Identifier: MIT
#

KERNEL_NAME ?= "cip"

WKS_FILE ?= "${MACHINE}.wks"

CIP_IMAGE_OPTIONS ?= ""

IMAGER_BUILD_DEPS:append = " dosfstools-native"
IMAGER_BUILD_DEPS:remove:buster = "dosfstools-native"
