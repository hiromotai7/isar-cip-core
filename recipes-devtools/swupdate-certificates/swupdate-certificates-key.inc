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

PROVIDES += "swupdate-certificates-key"

SWU_SIGN_KEY ??= ""
SWU_SIGN_SCRIPT ??= "sign-swu-cms"
SRC_URI:append = " ${@ "file://"+d.getVar('SWU_SIGN_KEY') if d.getVar('SWU_SIGN_KEY') else '' }"
SRC_URI:append = " ${@ "file://"+d.getVar('SWU_SIGN_SCRIPT') if d.getVar('SWU_SIGN_SCRIPT') else '' }"

do_install[cleandirs] = "${D}/usr/share/swupdate-signing/ \
                         ${D}/usr/bin/"
do_install() {
    if [ ! -f ${WORKDIR}/${SWU_SIGN_SCRIPT} ] ]; then
        bbfatal "You must add a '${SWU_SIGN_SCRIPT}' to execute the signing process"
    fi
    install -m 0700 ${WORKDIR}/${SWU_SIGN_SCRIPT} ${D}/usr/bin/sign-swu
    if [ -z ${SWU_SIGN_KEY} ] ]; then
        bbfatal "You must set SWU_SIGN_KEY and provide the required file as artifacts to this recipe"
    fi
    TARGET=${D}/usr/share/swupdate-signing/
    install -m 0600 ${WORKDIR}/${SWU_SIGN_KEY} ${TARGET}/swupdate-sign.key
}

do_prepare_build:append() {
    echo "Provides: swupdate-certificates-key" >> ${S}/debian/control
}
