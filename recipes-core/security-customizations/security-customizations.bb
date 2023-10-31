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

DESCRIPTION = "CIP Security configuration for IEC62443-4-2 evaluation"

SRC_URI = "file://postinst \
           file://ssh-remote-session-term.conf \
           file://ssh-pam-remote.conf"

DEPENDS = "customizations sshd-regen-keys"
DEBIAN_DEPENDS = "customizations, sshd-regen-keys, libpam-google-authenticator, libpam-modules, libpam-runtime, auditd"

# Package names based on the distro version
DEBIAN_DEPENDS:append:buster = ", libpam-cracklib"
DEBIAN_DEPENDS:append:bullseye = ", libpam-cracklib"
DEBIAN_DEPENDS:append:bookworm = ", libpam-passwdqc"

do_install[cleandirs] += "${D}/etc/ssh/sshd_config.d/"
do_install () {
    install -m 600 ${WORKDIR}/ssh-remote-session-term.conf ${D}/etc/ssh/sshd_config.d/
    install -m 600 ${WORKDIR}/ssh-pam-remote.conf ${D}/etc/ssh/sshd_config.d/
}
