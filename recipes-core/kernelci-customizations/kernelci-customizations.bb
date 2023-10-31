#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2019
# Copyright (c) Cybertrust Japan Co., Ltd., 2021
#
# Authors:
#  Jan Kiszka <jan.kiszka@siemens.com>
#  Alice Ferrazzi <alice.ferrazzi@miraclelinux.com>
#
# SPDX-License-Identifier: MIT
#

inherit dpkg-raw

DESCRIPTION = "CIP Core KernelCI image customizations"

DEPENDS += "customizations"
DEBIAN_DEPENDS += "customizations"

SRC_URI = "file://postinst \
           file://dmesg.sh \
           file://serial-getty-kernelci-override.conf \
           file://ssh-permit-empty-passwords.conf"

do_install[cleandirs] = "${D}/opt/kernelci/ \
                         ${D}/etc/systemd/system/serial-getty@.service.d/ \
                         ${D}/etc/ssh/sshd_config.d/"
do_install() {
  install -v -m 744 ${WORKDIR}/dmesg.sh ${D}/opt/kernelci/
  install -v -m 644 ${WORKDIR}/serial-getty-kernelci-override.conf ${D}/etc/systemd/system/serial-getty@.service.d/serial-getty-kernelci-override.conf
  install -v -m 600 ${WORKDIR}/ssh-permit-empty-passwords.conf ${D}/etc/ssh/sshd_config.d/ssh-permit-empty-passwords.conf
}
