#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2020-2023
#
# Authors:
#  Quirin Gylstorff <quirin.gylstorff@siemens.com>
#
# SPDX-License-Identifier: MIT
#

DESCRIPTION = "efibootguard boot loader"
DESCRIPTION_DEV = "efibootguard development library"
HOMEPAGE = "https://github.com/siemens/efibootguard"
LICENSE = "GPL-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_isar}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"
MAINTAINER = "Jan Kiszka <jan.kiszka@siemens.com>"

SRC_URI = " \
    https://github.com/siemens/efibootguard/archive/refs/tags/v0.13.tar.gz;downloadfilename=efibootguard_0.13.orig.tar.gz;unpack=0;name=tarball \
    git://salsa.debian.org/debian/efibootguard.git;protocol=https;branch=master;name=debian \
    file://debian-patches/0001-d-control-Make-compatible-with-debian-buster.patch \
    "
SRC_URI[tarball.sha256sum] = "639a6d8f687cb099b2e9b01eb08ad1494267fe26b5d903b4d405d0737feb989b"
SRCREV_debian = "e39728f63946d1af2d5edbecd89a30706dc31a9a"

# add riscv64 support
SRC_URI += "file://src-patches"

CHANGELOG_V = "${PV}+cip"

PROVIDES = "libebgenv-dev libebgenv0 efibootguard"

S = "${WORKDIR}/git"

PATCHTOOL = "git"

inherit dpkg

DEPENDS = "python3-shtab"
# needed for buster, bullseye could use compat >= 13
python() {
    arch = d.getVar('DISTRO_ARCH')
    cmd = 'dpkg-architecture -a {} -q DEB_HOST_MULTIARCH'.format(arch)
    with os.popen(cmd) as proc:
        d.setVar('DEB_HOST_MULTIARCH', proc.read())
}

CHANGELOG_V = "<orig-version>+isar"

do_prepare_build() {
    deb_add_changelog
    cd ${S}/debian
    quilt import ${WORKDIR}/src-patches/*.patch
}
