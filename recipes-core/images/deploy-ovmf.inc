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

INSTALL_deploy_ovmf_binaries += "ovmf"

do_deploy_ovmf_binaries[network] += "${TASK_USE_SUDO}"
do_deploy_ovmf_binaries[cleandirs] += "${DEPLOY_DIR_IMAGE}/OVMF"
do_deploy_ovmf_binaries[depends] += "${SCHROOT_DEP}"
do_deploy_ovmf_binaries() {
    imager_run -p -d ${PP_WORK} -- \
        sh -c 'cp -v /usr/share/OVMF/*.fd ${PP_DEPLOY}/OVMF/'
}
addtask deploy_ovmf_binaries after do_rootfs_install before do_image
