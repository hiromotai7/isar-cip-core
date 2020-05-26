#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2019
#
# Authors:
#  Christian Storm <christian.storm@siemens.com>
#
# SPDX-License-Identifier: MIT
#

DESCRIPTION = "U-Boot for BBB"

require recipes-bsp/u-boot/u-boot-custom.inc

U_BOOT_REV = "3c99166441bf3ea325af2da83cfe65430b49c066"

SRC_URI += " \
    git://gitlab.denx.de/u-boot/u-boot.git;rev=${U_BOOT_REV};protocol=https \
    file://boot-bbb.scr.in \
    file://fw_env.config \
    file://ubootenv-bbb"

# Build U-Boot with MLO (MLO does not build with $ make spl)
U_BOOT_BIN = ""

U_BOOT_CONFIG = "am335x_evm_defconfig"

S = "${WORKDIR}/git"

BUILD_DEPENDS =. "openssl, python-crypto:native, u-boot-tools,"

do_prepare_build_append() {
    echo "MLO /usr/lib/u-boot/${MACHINE}" > \
        ${S}/debian/u-boot-${MACHINE}.install
    echo "u-boot.img /usr/lib/u-boot/${MACHINE}" >> \
        ${S}/debian/u-boot-${MACHINE}.install

    echo "\ngen_bootscript:" >> ${S}/debian/rules
    echo "\tmkimage -A arm -O linux -T script -d ../boot-bbb.scr.in ../boot.scr" >> ${S}/debian/rules
    sed -i 's/\(override_dh_auto_build:\)/\1 gen_bootscript/' ${S}/debian/rules

    # Install BBB's fw_env.config
    install -v -m 0644 ${WORKDIR}/fw_env.config ${S}/tools/env/fw_env.config
}

dpkg_runbuild_append() {
    mkdir -p ${DEPLOY_DIR_IMAGE}
    install ${WORKDIR}/boot.scr ${DEPLOY_DIR_IMAGE}/boot.scr
    install ${WORKDIR}/ubootenv-bbb ${DEPLOY_DIR_IMAGE}/uboot.env
}

