#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2024
#
# Authors:
#  Jan Kiszka <jan.kiszka@siemens.com>
#
# SPDX-License-Identifier: MIT
#

inherit dpkg-raw

SRC_URI += "file://erofs.hook"

DEBIAN_DEPENDS = "erofs-utils"

do_install[cleandirs] += " \
    ${D}/usr/share/initramfs-tools/hooks"

do_install() {
    install -m 0755 "${WORKDIR}/erofs.hook" \
        "${D}/usr/share/initramfs-tools/hooks/erofs"
}
