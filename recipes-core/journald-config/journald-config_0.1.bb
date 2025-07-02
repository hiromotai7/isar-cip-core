#
# CIP Core, generic profile
#
# Copyright (c) Siemens, 2025
#
# Authors:
#  Quirin Gylstorff <quirin.gylstorff@siemens.com>
#
# SPDX-License-Identifier: MIT

inherit dpkg-raw

SRC_URI = "file://persistent-journal.conf"

do_install[cleandirs] = "${D}/usr/lib/systemd/journald.conf.d/"
do_install() {
    install -v -m 644 "${WORKDIR}"/persistent-journal.conf ${D}/usr/lib/systemd/journald.conf.d/
}
