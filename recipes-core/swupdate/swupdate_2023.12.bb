#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2024
#
# Authors:
#  Quirin Gylstorff <quirin.gylstorff@siemens.com>
#
# SPDX-License-Identifier: MIT

inherit dpkg

require swupdate.inc

DEPENDS += "libebgenv-dev"
DEPENDS += "libubootenv-dev"

DEB_BUILD_PROFILES += "nodoc"
DEB_BUILD_OPTIONS += "nodoc"

FILESEXTRAPATHS:prepend := "${FILE_DIRNAME}/files/${PV}:"

SRC_URI = "git://salsa.debian.org/debian/swupdate.git;protocol=https;branch=debian/master;destsuffix=${P}"

SRCREV = "6ccd44a8539ebb880bf0dac408d5db5de7e2de99"

# patches
SRC_URI += "file://0001-d-rules-Add-seperate-build_profile-option-for-delta-.patch"
SRC_URI += "file://0002-d-swupdate-www.install-Fix-path-for-debian-bullseye.patch"

# suricatta wfx requires suricatta lua and the dependency
# is not set automatically
DEB_BUILD_PROFILES += "pkg.swupdate.suricattalua"
# add suricatta wfx
DEB_BUILD_PROFILES += "pkg.swupdate.suricattawfx"

# Disable cross for arm and arm64 on bullseye
# with cross compile we have a unsat-dependency to dh-nodejs on arm/arm64
ISAR_CROSS_COMPILE:bullseye = "0"

# add cross build and deactivate testing for arm based builds
DEB_BUILD_PROFILES += "cross nocheck"

# use backport build profile for bullseye
DEB_BUILD_PROFILES += "pkg.swupdate.bpo"

CHANGELOG_V ?= "${PV}+cip-${SRCREV}"

do_prepare_build() {
    deb_add_changelog
    cd ${WORKDIR}
    tar cJf ${PN}_${PV}+cip.orig.tar.xz --exclude=.git --exclude=debian ${P}
}
