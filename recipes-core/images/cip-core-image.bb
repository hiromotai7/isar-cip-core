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

CIP_IMAGE_OPTIONS ?= ""
require ${CIP_IMAGE_OPTIONS}
