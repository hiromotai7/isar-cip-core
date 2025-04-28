#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2020-2024
#
# Authors:
#  Quirin Gylstorff <quirin.gylstorff@siemens.com>
#  Jan Kiszka <jan.kiszka@siemens.com>
#
# SPDX-License-Identifier: MIT

require recipes-initramfs/initramfs-hook/hook.inc

DEBIAN_DEPENDS .= ", util-linux"
DEBIAN_CONFLICTS = "initramfs-verity-hook"

SRC_URI += " \
    file://local-top-complete"

HOOK_COPY_EXECS = "lsblk sed"

