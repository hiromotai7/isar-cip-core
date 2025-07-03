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

SRC_URI:append = " ${@ \
    'git://gitlab.com/cip-project/cip-kernel/cip-kernel-config.git;protocol=https;branch=master;destsuffix=cip-kernel-config;name=cip-kernel-config' \
    if d.getVar('USE_CIP_KERNEL_CONFIG') == '1' else '' \
    }"

SRCREV_cip-kernel-config ?= "29e3fbfb85303cc4dc9797740df5d54f77f43feb"

do_fetch[vardeps] += "SRCREV_cip-kernel-config"

KBUILD_DEPENDS:append = "${@', lzop' if d.getVar('USE_CIP_KERNEL_CONFIG') == '1' else ''}"
