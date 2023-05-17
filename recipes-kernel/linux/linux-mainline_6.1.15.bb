# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2018-2023
#
# SPDX-License-Identifier: MIT

require recipes-kernel/linux/linux-custom.inc
require recipes-kernel/linux/cip-kernel-config.inc

ARCHIVE_VERSION = "${@ d.getVar('PV')[:-2] if d.getVar('PV').endswith('.0') else d.getVar('PV') }"

KERNEL_DEFCONFIG_VERSION ?= "6.1.y-cip"

SRC_URI += " \
    https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${ARCHIVE_VERSION}.tar.xz \
    file://squashfs.cfg"

SRC_URI[sha256sum] = "2c16dfe2168a2e64ac0d55a12d625ebfb963818bb48b60c1868c7c460644c4fd"

S = "${WORKDIR}/linux-${ARCHIVE_VERSION}"
