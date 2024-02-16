#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2023
#
# Authors:
#  Quirin Gylstorff <quirin.gylstorff@siemens.com>
#
# SPDX-License-Identifier: MIT

inherit dpkg

require swupdate.inc

DEPENDS += "libebgenv-dev"

DEB_BUILD_PROFILES += "nodoc"
DEB_BUILD_OPTIONS += "nodoc"

FILESEXTRAPATHS:prepend := "${FILE_DIRNAME}/files/2022.12:"

SRC_URI += "git://salsa.debian.org/debian/swupdate.git;protocol=https;branch=debian/master;destsuffix=${P}"

SRCREV = "aa9edf070567fa5b3e942c270633a8feef49dad8"
SRC_URI += "file://0001-Add-option-to-enable-surricatta-lua.patch"
SRC_URI += "file://0002-d-patches-Add-patch-to-add-the-build-version-to-swup.patch"

ISAR_CROSS_COMPILE:bullseye = "0"

DEB_BUILD_PROFILES += "pkg.swupdate.suricattalua"

# use backport build profile for bullseye
DEB_BUILD_PROFILES:append:bullseye = " pkg.swupdate.bpo"

CHANGELOG_V ?= "${PV}-${SRCREV}"

do_prepare_build() {
    deb_add_changelog
    cd ${WORKDIR}
    tar cJf ${PN}_${PV}.orig.tar.xz --exclude=.git --exclude=debian ${P}
}
