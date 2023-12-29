#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2023
#
# Authors:
#  Quirin Gylstorff <quirin.gylstorff@siemens.com>
#
# SPDX-License-Identifier: MIT

inherit dpkg-raw

SRC_URI = "file://jsontolibconf"

DEBIAN_DEPENDS = "python3-libconf"

DPKG_ARCH = "all"

do_install[cleandirs] = "${D}/usr/bin"
do_install() {
    install -m 755 ${WORKDIR}/jsontolibconf ${D}/usr/bin/
}
