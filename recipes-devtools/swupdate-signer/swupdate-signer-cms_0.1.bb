#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2024
#
# Authors:
#  Quirin Gylstorff <quirin.gylstorff@siemens.com>
#
# SPDX-License-Identifier: MIT

inherit dpkg-raw
DPKG_ARCH = "all"

PROVIDES = "swupdate-signer"
DEBIAN_PROVIDES = "swupdate-signer"

DEPENDS = "swupdate-certificates-key"
DEBIAN_DEPENDS += "openssl, swupdate-certificates-key"

SRC_URI = "file://sign-swu-cms"

do_install[cleandirs] = "${D}/usr/bin/"
do_install() {
    install -m 0755 ${WORKDIR}/sign-swu-cms ${D}/usr/bin/sign-swu
}
