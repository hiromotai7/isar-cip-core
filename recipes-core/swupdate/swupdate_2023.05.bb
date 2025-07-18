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

FILESEXTRAPATHS:prepend := "${FILE_DIRNAME}/files/${PV}:"

SRC_URI += "git://github.com/sbabic/swupdate.git;protocol=https;branch=master;name=upstream;destsuffix=${P}"
SRC_URI += "git://salsa.debian.org/debian/swupdate.git;protocol=https;branch=debian/master;name=debian;subpath=debian;destsuffix=${P}/debian"

SRCREV_debian = "78cb6f20319d2b911e170eea5305f2cf0bd33030"
SRCREV_upstream = "c8ca55684c375937dbcdefb0563071a35137f4ba"

# patches
SRC_URI += "file://0001-d-rules-Add-seperate-build_profile-option-for-delta-.patch \
            file://0002-d-patches-Add-patch-to-add-the-build-version-to-swup.patch \
            file://0003-d-rules-Add-option-to-enable-suricatta_wfx.patch"
SRC_URI:append:bullseye = " file://0004-d-swupdate-www.install-Fix-path-for-debian-bullseye.patch"

# The option: "pkg.swupdate.nosigning" disables the required signing
# of update binaries
# DEB_BUILD_PROFILES += "pkg.swupdate.nosigning"

# deactivate hardware compability for simple a/b rootfs update
DEB_BUILD_PROFILES += "pkg.swupdate.nohwcompat"

# suricatta wfx requires suricatta lua and the dependency
# is not set automatically
DEB_BUILD_PROFILES += "pkg.swupdate.suricattalua"
# add suricatta wfx
DEB_BUILD_PROFILES += "pkg.swupdate.suricattawfx"
# add delta update build profile for bookworm
DEB_BUILD_PROFILES += "pkg.swupdate.delta"

# Disable cross for arm and arm64 on bullseye
# with cross compile we have a unsat-dependency to dh-nodejs on arm/arm64
ISAR_CROSS_COMPILE:bullseye = "0"

# add cross build and deactivate testing for arm based builds
DEB_BUILD_PROFILES += "cross nocheck"

# use backport build profile for bullseye
DEB_BUILD_PROFILES:append:bullseye = " pkg.swupdate.bpo"

CHANGELOG_V ?= "${PV}+cip-${SRCREV_upstream}"

do_prepare_build() {
    deb_add_changelog
    cd ${WORKDIR}
    tar cJf ${PN}_${PV}+cip.orig.tar.xz --exclude=.git --exclude=debian ${P}
}
