#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2022-2023
#
# Authors:
#  Jan Kiszka <jan.kiszka@siemens.com>
#
# SPDX-License-Identifier: MIT
#

FILESEXTRAPATHS:prepend := "${FILE_DIRNAME}/files:"

KERNEL_DEFCONFIG ?= "${MACHINE}_defconfig"

require recipes-kernel/linux/linux-custom.inc
require recipes-kernel/linux/cip-kernel-config.inc

SRC_URI += " \
    https://git.kernel.org/pub/scm/linux/kernel/git/cip/linux-cip.git/snapshot/linux-cip-${PV}.tar.gz \
    "

S = "${WORKDIR}/linux-cip-${PV}"
