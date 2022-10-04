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

require common.inc

DESCRIPTION = "CIP Core image demo & customizations"

DEBIAN_DEPENDS_append_rzfive = ", linux-image-rzfive"

do_prepare_build_prepend_qemu-riscv64() {
	if ! grep -q serial-getty@hvc0.service ${WORKDIR}/postinst; then
		# suppress SBI console - overlaps with serial console
		echo >> ${WORKDIR}/postinst
		echo "systemctl mask serial-getty@hvc0.service" >> ${WORKDIR}/postinst
	fi
}

do_prepare_build_prepend_rzfive() {
	if ! grep -q ${DTB_FILES} ${WORKDIR}/postinst; then
		# set link to DTB for the legacy U-Boot bootcmd
		echo >> ${WORKDIR}/postinst
		echo "ln -s /usr/lib/linux-*/${DTB_FILES} /boot/production.dtb" >> ${WORKDIR}/postinst
		echo "gzip -c /boot/vmlinux-* > /boot/Image.gz" >> ${WORKDIR}/postinst
	fi
}
