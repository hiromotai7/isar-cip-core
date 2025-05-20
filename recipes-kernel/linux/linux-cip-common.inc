#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2022-2025
#
# Authors:
#  Jan Kiszka <jan.kiszka@siemens.com>
#
# SPDX-License-Identifier: MIT
#

FILESEXTRAPATHS:prepend := "${FILE_DIRNAME}/files:"

KERNEL_MAJOR_MINOR = "${@d.getVar('PV').split('.')[0] + '.' + d.getVar('PV').split('.')[1]}"

KERNEL_DEFCONFIG_VERSION ?= "${KERNEL_MAJOR_MINOR}.y-cip"
KERNEL_DEFCONFIG ?= "${MACHINE}_defconfig"

require recipes-kernel/linux/linux-custom.inc
require recipes-kernel/linux/cip-kernel-config.inc

SRC_URI += " \
    https://cdn.kernel.org/pub/linux/kernel/projects/cip/${KERNEL_MAJOR_MINOR}/linux-cip-${PV}.tar.xz \
    ${@'file://preempt-rt.cfg' if d.getVar('KERNEL_NAME') == 'cip-rt' else ''} \
    "

S = "${WORKDIR}/linux-cip-${PV}"
