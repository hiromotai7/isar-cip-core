#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2023
#
# Authors:
#  Quirin Gylstorff <quirin.gylstorff@siemens.com>
#
# SPDX-License-Identifier: MIT
#

inherit dpkg-raw

FILESEXTRAPATHS:prepend := "${FILE_DIRNAME}/files:"

DPKG_ARCH = "all"
PROVIDES += "swupdate-certificates-key"
DEBIAN_PROVIDES = "swupdate-certificates-key"

SWU_SIGN_KEY ??= ""
SRC_URI:append = " ${@ "file://"+d.getVar('SWU_SIGN_KEY') if d.getVar('SWU_SIGN_KEY') else '' }"

do_install[cleandirs] = "${D}/usr/share/swupdate-signing"
do_install() {
    if [ -z ${SWU_SIGN_KEY} ]; then
        bbfatal "You must set SWU_SIGN_KEY and provide the required file as artifacts to this recipe"
    fi
    TARGET=${D}/usr/share/swupdate-signing/
    install -m 0600 ${WORKDIR}/${SWU_SIGN_KEY} ${TARGET}/swupdate-sign.key
}

