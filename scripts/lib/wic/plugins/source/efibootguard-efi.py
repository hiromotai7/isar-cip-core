# ex:ts=4:sw=4:sts=4:et
# -*- tab-width: 4; c-basic-offset: 4; indent-tabs-mode: nil -*-
#
# Copyright (c) 2014, Intel Corporation.
# Copyright (c) 2018, Siemens AG.
# All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# DESCRIPTION
# This implements the 'efibootguard-efi' source plugin class for 'wic'
#
# AUTHORS
# Tom Zanussi <tom.zanussi (at] linux.intel.com>
# Claudius Heine <ch (at] denx.de>
# Andreas Reichel <andreas.reichel.ext (at] siemens.com>
# Christian Storm <christian.storm (at] siemens.com>

import logging
import os

msger = logging.getLogger('wic')

from wic.pluginbase import SourcePlugin
from wic.misc import exec_cmd, get_bitbake_var, BOOTDD_EXTRA_SPACE

class EfibootguardEFIPlugin(SourcePlugin):
    """
    Create EFI bootloader partition containing the EFI Boot Guard Bootloader.
    """

    name = 'efibootguard-efi'

    @classmethod
    def do_prepare_partition(cls, part, source_params, creator, cr_workdir,
                             oe_builddir, deploy_dir, kernel_dir,
                             rootfs_dir, native_sysroot):
        """
        Called to do the actual content population for a partition, i.e.,
        populate an EFI boot partition containing the EFI Boot Guard
        bootloader binary.
        """
        efiarch = get_bitbake_var("EFI_ARCH")
        if not efiarch:
            msger.error("Bitbake variable 'EFI_ARCH' not set, exiting\n")
            exit(1)
        libarch = get_bitbake_var("EFI_LIB_ARCH")
        if not libarch:
            msger.error("Bitbake variable 'EFI_LIB_ARCH' not set, exiting\n")
            exit(1)

        deploy_dir = get_bitbake_var("DEPLOY_DIR_IMAGE")
        if not deploy_dir:
            msger.error("DEPLOY_DIR_IMAGE not set, exiting\n")
            exit(1)
        creator.deploy_dir = deploy_dir

        deploy_dir = get_bitbake_var("DEPLOY_DIR_IMAGE")
        if not deploy_dir:
            msger.error("DEPLOY_DIR_IMAGE not set, exiting\n")
            exit(1)
        creator.deploy_dir = deploy_dir

        distro_arch = get_bitbake_var("DISTRO_ARCH")
        bootloader = "/usr/lib/{libpath}/efibootguard/efibootguard{efiarch}.efi".format(
                        libpath=libarch,
                        efiarch=efiarch)
        part_rootfs_dir = "%s/disk/%s.%s" % (cr_workdir,
                                             part.label,
                                             part.lineno)
        create_dir_cmd = "install -d %s/EFI/BOOT" % part_rootfs_dir
        exec_cmd(create_dir_cmd)

        name = "boot{}.efi".format(efiarch)

        signed_bootloader = cls._sign_file(name,
                                           bootloader,
                                           cr_workdir,
                                           source_params)
        cp_cmd = "cp %s/%s %s/EFI/BOOT/%s" % (cr_workdir,
                                              signed_bootloader,
                                              part_rootfs_dir,
                                              name)
        exec_cmd(cp_cmd, True)

        cp_to_deploy_cmd = "cp %s/%s %s/%s" % (cr_workdir,
                                               signed_bootloader,
                                               deploy_dir,
                                               name)
        exec_cmd(cp_to_deploy_cmd, True)

        efi_part_image = "%s/%s.%s.img" % (cr_workdir, part.label, part.lineno)
        part.prepare_rootfs_msdos(efi_part_image, cr_workdir, oe_builddir,
                                  part_rootfs_dir, native_sysroot, None)

        du_cmd = "du -Lbks %s" % efi_part_image
        efi_part_image_size = int(exec_cmd(du_cmd).split()[0])

        part.size = efi_part_image_size
        part.source_file = efi_part_image


    @classmethod
    def _sign_file(cls, name, signee, cr_workdir, source_params):
        sign_script = source_params.get("signwith")
        if sign_script and os.path.exists(sign_script):
            work_name = name.replace(".efi", ".signed.efi")
            sign_cmd = "{sign_script} {signee} \
            {cr_workdir}/{work_name}".format(sign_script=sign_script,
                                             signee=signee,
                                             cr_workdir=cr_workdir,
                                             work_name=work_name)
            exec_cmd(sign_cmd)
        elif sign_script and not os.path.exists(sign_script):
            msger.error("Could not find script %s", sign_script)
            exit(1)
        else:
            # if we do nothing copy the signee to the work directory
            work_name = name
            cp_cmd = "cp {signee} {cr_workdir}/{work_name}".format(
                signee=signee,
                cr_workdir=cr_workdir,
                work_name=work_name)
            exec_cmd(cp_cmd)
        return work_name
