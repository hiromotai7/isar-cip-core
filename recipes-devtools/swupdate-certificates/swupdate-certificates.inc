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

PROVIDES += "swupdate-certificates"

SWU_SIGN_CERT ??= ""

SRC_URI:append = " ${@ "file://"+d.getVar('SWU_SIGN_CERT') if d.getVar('SWU_SIGN_CERT') else '' }"

do_install() {
    if [ -z ${SWU_SIGN_CERT} ] ]; then
        bbfatal "You must set SWU_SIGN_CERT and provide the required file as artifacts to this recipe"
    fi
    TARGET=${D}/usr/share/swupdate-signing/
    install -d -m 0700 ${TARGET}
    install -m 0700 ${WORKDIR}/${SWU_SIGN_CERT} ${TARGET}/swupdate-sign.crt
}

do_prepare_build:append() {
    echo "Provides: swupdate-certificates" >> ${S}/debian/control
}
