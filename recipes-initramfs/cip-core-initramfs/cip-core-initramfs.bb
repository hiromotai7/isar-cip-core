#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2021 - 2023
#
# Authors:
#  Quirin Gylstorff <quirin.gylstorff@siemens.com>
#
# SPDX-License-Identifier: MIT
#

inherit initramfs

INITRAMFS_INSTALL += " \
    initramfs-factory-reset-hook \
    initramfs-data-reset-hook \
    initramfs-overlay-hook \
    "

INITRAMFS_INSTALL:append:encrypt-partitions = " initramfs-crypt-hook"
