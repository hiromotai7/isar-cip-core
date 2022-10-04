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

require recipes-kernel/linux/linux-custom.inc

SRC_URI += " \
    https://github.com/renesas-rz/rz_linux-cip/archive/${SRCREV}.tar.gz \
    file://0001-riscv-fix-build-with-binutils-2.38.patch"
SRC_URI[sha256sum] = "86cb2d9fdfea9d52b9239e3d091ffadca2dd76b530ac151feb67e728b8d006ad"
SRCREV = "48de75691cc8f3c5fd75a784c7c42110752e268e"

KERNEL_DEFCONFIG ?= "renesas_defconfig"

S = "${WORKDIR}/rz_linux-cip-${SRCREV}"
