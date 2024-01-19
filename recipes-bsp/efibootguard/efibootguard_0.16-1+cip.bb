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

EBG_VERSION = "${@d.getVar('PV').split('-')[0]}"

SRC_URI = " \
    https://github.com/siemens/efibootguard/archive/refs/tags/v${EBG_VERSION}.tar.gz;downloadfilename=efibootguard_${EBG_VERSION}.orig.tar.gz;unpack=0;name=tarball \
    git://salsa.debian.org/debian/efibootguard.git;protocol=https;branch=master;name=debian \
    file://debian-patches/0001-d-control-Make-compatible-with-debian-buster.patch \
    "
SRC_URI[tarball.sha256sum] = "d6d37c59aed17489d02b4f0b63db16994dfb8f9f70f54be4d65c366f58c6be9d"
SRCREV_debian = "eacf94e767136a0257850ea0c888d234cb8cace4"

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

do_prepare_build() {
    deb_add_changelog
}
