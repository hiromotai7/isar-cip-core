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

SRC_URI:append = " ${@ \
    'git://gitlab.com/Quirin.Gy/cip-kernel-config.git;protocol=https;branch=quirin/fix-arm-merged-config;destsuffix=cip-kernel-config;name=cip-kernel-config' \
    if d.getVar('USE_CIP_KERNEL_CONFIG') == '1' else '' \
    }"

KBUILD_DEPENDS:append = " ${@ \
    'lzop, lz4' \
    if d.getVar('USE_CIP_KERNEL_CONFIG') == '1' else '' \
    }"

SRCREV_cip-kernel-config ?= "f6092ac6fbc09755fd21e701eff08e19e892da19"

do_fetch[vardeps] += "SRCREV_cip-kernel-config"
