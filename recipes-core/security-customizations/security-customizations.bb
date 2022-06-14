#
# CIP Security, generic profile
#
# Copyright (c) Toshiba Corporation, 2020
#
# Authors:
#  Venkata Pyla <venkata.pyla@toshiba-tsip.com>#
#
# SPDX-License-Identifier: MIT
#

inherit dpkg-raw

DESCRIPTION = "CIP Security image for IEC62443-4-2 evaluation"

SRC_URI = " file://postinst \
	    file://ethernet"

DEPENDS = "sshd-regen-keys"
DEBIAN_DEPENDS = "ifupdown, isc-dhcp-client, net-tools, iputils-ping, ssh, sshd-regen-keys"

do_install() {
        install -v -d ${D}/etc/network/interfaces.d
        install -v -m 644 ${WORKDIR}/ethernet ${D}/etc/network/interfaces.d/
}

