#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2023
#
# Authors:
#  Felix Moessbauer <felix.moessbauer@siemens.com>
#
# SPDX-License-Identifier: MIT
#
# This recipe deploys the OVMF binaries to run the image in QEMU
# Note: x86 only

IMAGER_INSTALL += "ovmf"

do_deploy_ovmf_binaries[cleandirs] += "${DEPLOY_DIR_IMAGE}/OVMF"
do_deploy_ovmf_binaries() {
    cp -v ${BUILDCHROOT_DIR}/usr/share/OVMF/*.fd ${DEPLOY_DIR_IMAGE}/OVMF
}

addtask deploy_ovmf_binaries after do_install_imager_deps before do_image
