#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2022-2024
#
# Authors:
#  Jan Kiszka <jan.kiszka@siemens.com>
#
# SPDX-License-Identifier: MIT
#

require u-boot-common-${PV}.inc
require u-boot-qemu-common.inc

# we run as OpenSBI payload, hence use smode
U_BOOT_CONFIG = "${MACHINE}_smode_defconfig"

U_BOOT_BIN = "u-boot.bin"
