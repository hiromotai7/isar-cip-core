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

SRC_URI:append = " ${@ \
    'git://gitlab.com/cip-project/cip-kernel/cip-kernel-config.git;protocol=https;branch=master;destsuffix=cip-kernel-config;name=cip-kernel-config' \
    if d.getVar('USE_CIP_KERNEL_CONFIG') == '1' else '' \
    }"

SRCREV_cip-kernel-config ?= "aca5978b5abf93b20df4efda067c3a3f461476e0"
