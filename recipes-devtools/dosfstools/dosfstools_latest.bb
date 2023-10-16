#
# CIP Core, generic profile
#
# Copyright (c) Toshiba Corporation 2023
#
# Authors:
#  Venkata Pyla <venkata.pyla@toshiba-tsip.com>
#
# SPDX-License-Identifier: MIT
#

inherit dpkg

CHANGELOG_V="<orig-version>+cip"

SRC_URI = "apt://${PN}"
SRC_URI += "file://0001-Honor-the-SOURCE_DATE_EPOCH-variable.patch;apply=no"

do_prepare_build() {
	deb_add_changelog

	cd ${S}
	quilt import ${WORKDIR}/*.patch
	quilt push -a
}
