#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2024
#
# Authors:
#  Felix Moessbauer <felix.moessbauer@siemens.com>
#
# SPDX-License-Identifier: MIT

# Note: This requires debhelper-compat 13, which limits it to bookworm

inherit dpkg-raw

MAINTAINER = "Felix Moessbauer <felix.moessbauer@siemens.com>"
DESCRIPTION = "Config to link volatile data to immutable copies"

SRC_URI = "file://${BPN}.tmpfiles"
DPKG_ARCH = "all"

do_prepare_build:append() {
    cp ${WORKDIR}/${BPN}.tmpfiles ${S}/debian/
}
