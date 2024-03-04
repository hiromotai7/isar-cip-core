#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2024
#
# Authors:
#  Quirin Gylstorff <quirin.gylstorff@siemens.com>
#
# SPDX-License-Identifier: MIT
#

inherit dpkg-raw

SRC_URI = "file://swupdate.cfg \
           file://hwrevision.tmpl"

MACHINE_HW_VERSION ??= "cip-core-1.0"
TEMPLATE_FILES += "hwrevision.tmpl"
TEMPLATE_VARS += "MACHINE MACHINE_HW_VERSION"

do_install[cleandirs] = "${D}/etc/"
do_install() {
    install -v -m 644 "${WORKDIR}"/swupdate.cfg "${D}"/etc/
    if [ -n "${MACHINE_HW_VERSION}" ]; then
        install -v -m 644 "${WORKDIR}"/hwrevision "${D}"/etc/
    fi
}
