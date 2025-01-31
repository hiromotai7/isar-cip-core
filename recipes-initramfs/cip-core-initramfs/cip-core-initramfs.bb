#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2021 - 2025
#
# Authors:
#  Quirin Gylstorff <quirin.gylstorff@siemens.com>
#
# SPDX-License-Identifier: MIT
#

inherit initramfs

INITRAMFS_INSTALL += " \
    initramfs-overlay-hook \
    "

INITRAMFS_INSTALL:append:abvar = " initramfs-abvar-hook"
INITRAMFS_INSTALL:append:encrypt-partitions = " initramfs-crypt-hook"
