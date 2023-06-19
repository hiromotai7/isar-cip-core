#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2023
#
# Authors:
#  Quirin Gylstorff <quirin.gylstorff@siemens.com>
#
# SPDX-License-Identifier: MIT

inherit dpkg-gbp

require swupdate.inc

DEPENDS += "libebgenv-dev"

DEB_BUILD_PROFILES += "nodoc"
DEB_BUILD_OPTIONS += "nodoc"

SRC_URI = "git://salsa.debian.org/debian/swupdate.git;protocol=https;branch=debian/master"
SRCREV ="aa9edf070567fa5b3e942c270633a8feef49dad8"
SRC_URI += "file://0001-d-rules-Add-option-for-suricatta_lua.patch"
SRC_URI += "file://0001-d-patches-Add-patch-to-add-the-build-version-to-swup.patch"

# deactivate signing and hardware compability for simple a/b rootfs update
DEB_BUILD_PROFILES += "pkg.swupdate.nosigning"
DEB_BUILD_PROFILES += "pkg.swupdate.nohwcompat"

# use suricatta-lua instead of suricatta-hawkbit
# DEB_BUILD_PROFILES = "pkg.swupdate.suricattalua"

# Disable cross for arm and arm64 on bullseye
# with cross compile we have a unsat-dependency to dh-nodejs on arm/arm64
ISAR_CROSS_COMPILE:bullseye = "0"

# add cross build and deactivate testing for arm based builds
DEB_BUILD_PROFILES += "cross nocheck"

# use backport build profile for bullseye
DEB_BUILD_PROFILES:append:bullseye = " pkg.swupdate.bpo"

CHANGELOG_V ?= "2022.12+dfsg-4+cip+${SRCREV}"

do_prepare_build() {
    deb_add_changelog
}
