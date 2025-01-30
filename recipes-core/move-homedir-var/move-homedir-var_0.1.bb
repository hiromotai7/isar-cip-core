#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2025
#
# Authors:
#  Quirin Gylstorff <quirin.gylstorff@siemens.com>
#
# SPDX-License-Identifier: MIT

inherit dpkg-raw

DEBIAN_CONFLICTS = "home-fs"
SRC_URI = "file://postinst \
           file://${BPN}.tmpfiles.tmpl"
DPKG_ARCH = "all"

IMMUTABLE_DATA_DIR ??= "usr/share/immutable-data"
TEMPLATE_VARS = "IMMUTABLE_DATA_DIR"
TEMPLATE_FILES += "${BPN}.tmpfiles.tmpl"

do_prepare_build:append() {
    cp ${WORKDIR}/${BPN}.tmpfiles ${S}/debian/
}
