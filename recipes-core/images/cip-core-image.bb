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

require cip-core-image.inc

DESCRIPTION = "CIP Core image"

IMAGE_INSTALL += "customizations"
IMAGE_INSTALL += "factory-reset-helper"
CIP_IMAGE_OPTIONS ?= ""
require ${CIP_IMAGE_OPTIONS}
