#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2022
#
# Authors:
#  Christian Storm <christian.storm@siemens.com>
#
# SPDX-License-Identifier: MIT
#

DESCRIPTION = "U-Boot for BBB"

# To build u-boot-tools package
U_BOOT_TOOLS_PACKAGE = "1"
U_BOOT_CONFIG_PACKAGE = "1"

require recipes-bsp/u-boot/u-boot-custom.inc

U_BOOT_REV = "c4fddedc48f336eabc4ce3f74940e6aa372de18c"

SRC_URI += " \
    git://gitlab.denx.de/u-boot/u-boot.git;rev=${U_BOOT_REV};protocol=https \
    file://boot-bbb.scr.in \
    file://fw_env.config \
    file://ubootenv-bbb"

# Build U-Boot with MLO (MLO does not build with $ make spl)
U_BOOT_BIN = ""

U_BOOT_CONFIG = "am335x_evm_defconfig"

S = "${WORKDIR}/git"

DEBIAN_BUILD_DEPENDS =. "openssl, u-boot-tools,"

do_prepare_build_append() {
    echo "MLO /usr/lib/u-boot/${MACHINE}" > \
        ${S}/debian/u-boot-${MACHINE}.install
    echo "u-boot.img /usr/lib/u-boot/${MACHINE}" >> \
        ${S}/debian/u-boot-${MACHINE}.install
    echo "tools/env/fw_printenv   /usr/bin/" >> \
        ${S}/debian/u-boot-tools.install
    echo "tools/env/fw_env.config	/etc" >> \
        ${S}/debian/u-boot-tools.install

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
