#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2023
#
# Authors:
#  Jan Kiszka <jan.kiszka@siemens.com>
#
# SPDX-License-Identifier: MIT
#

inherit dpkg

CHANGELOG_V="<orig-version>+cip"

SRC_URI = "apt://${BPN}"
SRC_URI += "file://0001-ARM32-Split-headers-and-code.patch;apply=no"

do_prepare_build() {
	deb_add_changelog

	cd ${S}
	quilt import -f ${WORKDIR}/*.patch
	quilt push -a
}
