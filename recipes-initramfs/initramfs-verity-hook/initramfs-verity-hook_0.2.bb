#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2021-2024
#
# Authors:
#  Quirin Gylstorff <quirin.gylstorff@siemens.com>
#
# SPDX-License-Identifier: MIT
#

require recipes-initramfs/initramfs-hook/hook.inc

SRC_URI += " \
    file://hook \
    file://local-top-complete.tmpl \
    "

VERITY_BEHAVIOR_ON_CORRUPTION ?= "--restart-on-corruption"

TEMPLATE_FILES += "local-top-complete.tmpl"
TEMPLATE_VARS += "VERITY_BEHAVIOR_ON_CORRUPTION"

DEBIAN_DEPENDS .= ", cryptsetup"
DEBIAN_CONFLICTS = "initramfs-abrootfs-hook"

HOOK_ADD_MODULES = "dm_mod dm_verity"
HOOK_COPY_EXECS = "veritysetup dmsetup sed"
