#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2019-2022
#
# Authors:
#  Jan Kiszka <jan.kiszka@siemens.com>
#
# SPDX-License-Identifier: MIT
#

inherit dpkg-raw

FILESPATH:append := ":${FILE_DIRNAME}/files"

SRC_URI = " \
    file://postinst.tmpl \
    file://ethernet \
    file://99-silent-printk.conf \
    file://99-watchdog.conf"

SRC_URI:append:swupdate = " file://swupdate.cfg"

CUSTOM_HOSTNAME ??= "demo"
WIRELESS_FIRMWARE_PACKAGE ?= ""
INSTALL_WIRELESS_TOOLS ??= "0"

TEMPLATE_FILES += "postinst.tmpl"
TEMPLATE_VARS += "CUSTOM_HOSTNAME"

DEPENDS += "sshd-regen-keys change-root-homedir"

DEBIAN_DEPENDS = " \
    ifupdown, isc-dhcp-client, net-tools, iputils-ping, ssh, sshd-regen-keys, \
    change-root-homedir \
    ${@(', iw, wireless-regdb, ' + d.getVar('WIRELESS_FIRMWARE_PACKAGE')) \
	if d.getVar('INSTALL_WIRELESS_TOOLS') == '1' else ''}"

do_install() {
	install -v -d ${D}/etc/network/interfaces.d
	install -v -m 644 ${WORKDIR}/ethernet ${D}/etc/network/interfaces.d/

	install -v -d ${D}/etc/sysctl.d
	install -v -m 644 ${WORKDIR}/99-silent-printk.conf ${D}/etc/sysctl.d/

	install -v -d ${D}/etc/systemd/system.conf.d
	install -v -m 644 ${WORKDIR}/99-watchdog.conf ${D}/etc/systemd/system.conf.d/
}

do_install:append:swupdate() {
	install -v -m 644 ${WORKDIR}/swupdate.cfg ${D}/etc/
}
