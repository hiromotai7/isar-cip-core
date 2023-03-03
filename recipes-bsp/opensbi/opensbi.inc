#
# Copyright (c) Siemens AG, 2023
#
# SPDX-License-Identifier: MIT

inherit dpkg

U_BOOT_PACKAGE ?= "u-boot-${MACHINE}"
PLATFORM ?= "generic"

DEPLOYDIR_FIRMWARE = "${WORKDIR}/deploy-fw"
SSTATETASKS += "do_deploy"

SRC_URI = " \
    https://github.com/riscv/opensbi/archive/v${PV}.tar.gz;downloadfilename=opensbi-${PV}.tar.gz;name=opensbi"

S = "${WORKDIR}/opensbi-${PV}"

DEPENDS += "${U_BOOT_PACKAGE}"
DEBIAN_BUILD_DEPENDS .= ",${U_BOOT_PACKAGE}"

do_prepare_build[cleandirs] += "${S}/debian"
do_prepare_build() {
    cp ${WORKDIR}/${MACHINE}-rules ${WORKDIR}/rules
    deb_debianize

    echo "build/platform/${PLATFORM}/firmware/fw_payload.bin /usr/lib/opensbi/${MACHINE}/" > ${S}/debian/install
}

do_deploy[cleandirs] += "${DEPLOYDIR_FIRMWARE}"
do_deploy[sstate-inputdirs] = "${DEPLOYDIR_FIRMWARE}"
do_deploy[sstate-outputdirs] = "${DEPLOY_DIR_IMAGE}"
do_deploy() {
    dpkg --fsys-tarfile "${WORKDIR}/${PN}_${PV}_${DISTRO_ARCH}.deb" | \
        tar xOf - "./usr/lib/opensbi/${MACHINE}/fw_payload.bin" \
        > "${DEPLOYDIR_FIRMWARE}/fw_payload.bin"
}

python do_deploy_setscene () {
    sstate_setscene(d)
}
addtask do_deploy_setscene

addtask deploy after do_dpkg_build before do_deploy_deb
