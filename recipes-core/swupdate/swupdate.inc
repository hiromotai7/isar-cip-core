#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2021-2023
#
# Authors:
#  Quirin Gylstorff <quirin.gylstorff@siemens.com>
#
# SPDX-License-Identifier: MIT

DESCRIPTION = "swupdate utility for software updates"
HOMEPAGE= "https://github.com/sbabic/swupdate"
LICENSE = "GPL-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_isar}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

PROVIDES += "libswupdate-dev"
PROVIDES += "libswupdate0.1"
PROVIDES += "lua-swupdate"


def get_bootloader_dependencies(d):
    bootloader = d.getVar("SWUPDATE_BOOTLOADER") or ""
    if bootloader == "efibootguard":
        return "libebgenv-dev"
    if bootloader == "u-boot":
        if bb.utils.to_boolean(d.getVar("U_BOOT_CONFIG_PACKAGE")):
            return "libubootenv u-boot-{}-config".format(d.getVar("MACHINE"))
        else:
            return "libubootenv"
    return ""

DEPENDS += "${@get_bootloader_dependencies(d)}"
DEPENDS += "${@bb.utils.contains('DEB_BUILD_PROFILES', 'mtd', 'mtd-utils', '', d)}"

DEB_BUILD_PROFILES += "${@'pkg.swupdate.nosigning' if not bb.utils.to_boolean(d.getVar('SWU_SIGNED')) else ''}"

# deactivate hardware compability for simple a/b rootfs update
DEB_BUILD_PROFILES += "pkg.swupdate.nohwcompat"

# add cross build and deactivate testing for arm based builds
DEB_BUILD_PROFILES += "cross nocheck"

python do_check_bootloader () {
    bootloader = d.getVar("SWUPDATE_BOOTLOADER") or "None"
    if not bootloader in ["efibootguard", "u-boot"]:
        bb.warn("swupdate: SWUPDATE_BOOTLOADER set to incompatible value: " + bootloader)
}
addtask check_bootloader before do_fetch
