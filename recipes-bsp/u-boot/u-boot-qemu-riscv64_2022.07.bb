#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2022
#
# Authors:
#  Jan Kiszka <jan.kiszka@siemens.com>
#
# SPDX-License-Identifier: MIT
#

require u-boot-qemu-common.inc

# we run as OpenSBI payload, hence use smode
U_BOOT_CONFIG = "${MACHINE}_smode_defconfig"

EFI_ARCH = "riscv64"

SRC_URI += " \
    file://riscv64/0001-riscv-Fix-build-against-binutils-2.38.patch"

U_BOOT_BIN = "u-boot.bin"
