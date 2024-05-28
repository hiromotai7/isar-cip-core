# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2024
#
# Authors:
#  Quirin Gylstorff <quirin.gylstorff@siemens.com>
#
# SPDX-License-Identifier: MIT
#
DESCRIPTION = "Basic fail2ban config with systemd as backend"

inherit dpkg-raw

DPKG_ARCH = "all"

SRC_URI += "file://systemd-defaults.conf"

DEBIAN_DEPENDS += "fail2ban, python3-systemd, python3-pyinotify"

do_install[cleandirs] = "${D}/etc/fail2ban/jail.d/"
do_install() {
    install -m 644 ${WORKDIR}/systemd-defaults.conf ${D}/etc/fail2ban/jail.d/
}
