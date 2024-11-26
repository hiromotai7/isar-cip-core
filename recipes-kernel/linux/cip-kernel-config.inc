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
    'git://gitlab.com/cip-project/cip-kernel/cip-kernel-config.git;protocol=https;branch=master;destsuffix=cip-kernel-config;name=cip-kernel-config' \
    if d.getVar('USE_CIP_KERNEL_CONFIG') == '1' else '' \
    }"

SRCREV_cip-kernel-config ?= "bb2485db01c5ce14ec571b9fb9e03f90c686a69f"

do_fetch[vardeps] += "SRCREV_cip-kernel-config"

KBUILD_DEPENDS:append = "${@', lzop' if d.getVar('USE_CIP_KERNEL_CONFIG') == '1' else ''}"
