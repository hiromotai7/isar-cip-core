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

SRCREV_cip-kernel-config ?= "f6b7018cb6845f34f8a03c126bf4f823ce10d637"

do_fetch[vardeps] += "SRCREV_cip-kernel-config"
