#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2023-2024
#
# Authors:
#  Felix Moessbauer <felix.moessbauer@siemens.com>
#
# SPDX-License-Identifier: MIT
#
# This class adds a mechanism to deploy files to the DEPLOY_DIR_IMAGE
# directory. Simply overwrite the deploy_firmware task and copy the
# to-be-deployed files into DEPLOYDIR_FIRMWARE.

inherit dpkg-base

DEPLOYDIR_FIRMWARE = "${WORKDIR}/deploy-fw"
SSTATETASKS += "do_deploy_firmware"

do_deploy_firmware[cleandirs] += "${DEPLOYDIR_FIRMWARE}"
do_deploy_firmware[sstate-inputdirs] = "${DEPLOYDIR_FIRMWARE}"
do_deploy_firmware[sstate-outputdirs] = "${DEPLOY_DIR_IMAGE}"
do_deploy_firmware() {
    die "This should never be called, overwrite it in your derived class"
}

python do_deploy_firmware_setscene () {
    sstate_setscene(d)
}
addtask deploy_firmware_setscene

addtask deploy_firmware after do_dpkg_build before do_deploy_deb
