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
DEBIAN_MULTI_ARCH = "foreign"

PROVIDES = "swupdate-signer"
DEBIAN_PROVIDES = "swupdate-signer"

do_install[cleandirs] = "${D}/usr/bin/"
do_install() {
    printf "#!/bin/sh\necho "empty-signer" > \$2 \n" > ${WORKDIR}/empty-signer
    install -m 0755 ${WORKDIR}/empty-signer ${D}/usr/bin/sign-swu
}
