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
DPKG_ARCH = "all"
DESCRIPTION = "helper script to execute a factory reset with a file"

# The efivariable is defined by ${FACTORY_RESET_MARKER}-${FACTORY_RESET_EFIVARS_GUID}
FACTORY_RESET_MARKER ?= "FactoryReset"
# use a self defined efivar guid as the efivarfs does not allow to use the
# guid
FACTORY_RESET_EFIVARS_GUID ?= "0979a3d9-b68d-416d-9668-76417a95b107"

SRC_URI = "file://set-factory-reset-efivar.sh.tmpl \
           file://get-factory-reset-efivar.sh.tmpl"

TEMPLATE_FILES += "set-factory-reset-efivar.sh.tmpl \
                   get-factory-reset-efivar.sh.tmpl"
TEMPLATE_VARS += " FACTORY_RESET_MARKER \
                   FACTORY_RESET_EFIVARS_GUID"
DEBIAN_DEPENDS .= ", coreutils, util-linux, e2fsprogs, bsdextrautils, efivar"

do_install[cleandirs] += "${D}/usr/sbin/"
do_install:prepend() {
    install -m 0700 "${WORKDIR}/set-factory-reset-efivar.sh" \
        "${D}/usr/sbin/set-factory-reset.sh"
    install -m 0700 "${WORKDIR}/get-factory-reset-efivar.sh" \
        "${D}/usr/sbin/get-factory-reset.sh"
}

