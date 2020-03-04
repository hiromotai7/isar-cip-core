#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2019
#
# Authors:
#  Christian Storm <christian.storm@siemens.com>
#
# SPDX-License-Identifier: MIT
#

DESCRIPTION = "SWUpdate"
HOMEPAGE= "https://github.com/sbabic/swupdate"
LICENSE = "GPL-2.0"

SRC_URI = "gitsm://github.com/sbabic/swupdate.git;branch=master;protocol=https"
SRCREV  = "f811c91c06bffe32f46472524059914987e653ba"
PV      = "2019.04+-git+isar"

SWUPDATE_DEFCONFIG ?= "swupdate_defconfig"
SWUPDATE_LUASCRIPT ?= "swupdate_handlers.lua"

SRC_URI += "file://debian \
            file://${SWUPDATE_DEFCONFIG} \
            file://swupdate.cfg \
            file://swupdate.service \
            file://swupdate.socket \
            file://${SWUPDATE_LUASCRIPT}"

inherit dpkg

python () {
    distro_arch = d.getVar("DISTRO_ARCH", True) or "None"
    bootloader  = d.getVar("SWUPDATE_BOOTLOADER", True) or "None"
    if distro_arch == "amd64" and bootloader == "None":
        d.setVar("SWUPDATE_BOOTLOADER", "efibootguard")
}

def get_crossnative_deps(d):
    crossnative = d.getVar("ISAR_CROSS_COMPILE", True) or "0"
    bootloader  = d.getVar("SWUPDATE_BOOTLOADER", True) or "None"
    if crossnative == "1" and bootloader == "u-boot":
        return " crossbuild-essential-armhf:native, u-boot-tools:native, "

def get_bootloader_deps(d, concern):
    bootloader = d.getVar("SWUPDATE_BOOTLOADER", True) or "None"
    if bootloader == "None":
        return ""
    deps = {
        'deb_deps': {
            'efibootguard': "efibootguard-dev",
            'u-boot': "u-boot-${MACHINE}-dev"
        },
        'bb_deps': {
            'efibootguard': "efibootguard-dev",
            'u-boot': "u-boot-${MACHINE}-dev"
        },
        'runtime_deps': {
            'efibootguard': "efibootguard",
            'u-boot': "u-boot-tools"
        }
    }
    return deps[concern][bootloader]

python do_check_bootloader () {
    bootloader = d.getVar("SWUPDATE_BOOTLOADER", True) or "None"
    if not bootloader in ["efibootguard", "u-boot"]:
        bb.warn("swupdate: SWUPDATE_BOOTLOADER set to unsupported value: " + bootloader)
}
addtask check_bootloader before do_fetch

BUILD_DEPENDS   = "liblua5.3-dev, librsync-dev, libconfig-dev, libarchive-dev, python-sphinx:native, dh-systemd, libsystemd-dev, "
BUILD_DEPENDS  += "${@get_crossnative_deps(d)}"
BUILD_DEPENDS  += "${@get_bootloader_deps(d, "deb_deps")}"
DEPENDS        += "${@get_bootloader_deps(d, "bb_deps")}"
RUNTIME_DEPENDS = "${@get_bootloader_deps(d, "runtime_deps")}"

S = "${WORKDIR}/git"

TEMPLATE_FILES = "debian/changelog.tmpl debian/control.tmpl debian/rules.tmpl"
TEMPLATE_VARS += "BUILD_DEPENDS SWUPDATE_DEFCONFIG RUNTIME_DEPENDS"

do_prepare_build() {
    cp -R ${WORKDIR}/debian ${S}

    ## copy defconfig and Lua handler
    install -m 0644 ${WORKDIR}/${SWUPDATE_LUASCRIPT} ${S}
    install -m 0644 ${WORKDIR}/${SWUPDATE_DEFCONFIG} ${S}/configs/${SWUPDATE_DEFCONFIG}
    if [ "${SWUPDATE_BOOTLOADER}" = "u-boot" ]; then
        echo 'CONFIG_UBOOT=y' >> ${S}/configs/${SWUPDATE_DEFCONFIG}
        echo 'CONFIG_UBOOT_FWENV="/etc/fw_env.config"' >> ${S}/configs/${SWUPDATE_DEFCONFIG}
    fi
    if [ "${SWUPDATE_BOOTLOADER}" = "efibootguard" ]; then
        echo 'CONFIG_BOOTLOADER_EBG=y' >> ${S}/configs/${SWUPDATE_DEFCONFIG}
    fi

    ## copy systemd service/socket unit files and swupdate.cfg
    cp ${WORKDIR}/swupdate.service ${S}/debian/swupdate.service
    cp ${WORKDIR}/swupdate.socket  ${S}/debian/swupdate.socket
    install -m 0644 ${WORKDIR}/${PN}.cfg ${S}/${PN}.cfg
}

