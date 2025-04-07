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
import re
from glob import glob

msger = logging.getLogger('wic')

from wic import WicError
from wic.pluginbase import SourcePlugin
from wic.misc import exec_cmd, get_bitbake_var, BOOTDD_EXTRA_SPACE

class EfibootguardEFIPlugin(SourcePlugin):
    """
    Create EFI bootloader partition containing the EFI Boot Guard Bootloader.
    """

    name = 'efibootguard-efi'

    @classmethod
    def _deploy_additional_boot_files(cls, boot_files, kernel_dir, part_rootfs_dir):
        # based on bootimg-efi-isar.py to get consistent behavior
        # list of tuples (src_name, dst_name)
        deploy_files = []
        for src_entry in re.findall(r'[\w;\-\./\*]+', boot_files):
            if ';' in src_entry:
                dst_entry = tuple(src_entry.split(';'))
                if not dst_entry[0] or not dst_entry[1]:
                    raise WicError('Malformed boot file entry: %s' % src_entry)
            else:
                dst_entry = (src_entry, src_entry)

            msger.debug('Destination entry: %r', dst_entry)
            deploy_files.append(dst_entry)

            install_task = []
            for deploy_entry in deploy_files:
                src, dst = deploy_entry
                if '*' in src:
                    # by default install files under their basename
                    entry_name_fn = os.path.basename
                    if dst != src:
                        # unless a target name was given, then treat name
                        # as a directory and append a basename
                        entry_name_fn = lambda name: \
                                        os.path.join(dst,
                                                     os.path.basename(name))

                    srcs = glob(os.path.join(kernel_dir, src))

                    msger.debug('Globbed sources: %s', ', '.join(srcs))
                    for entry in srcs:
                        src = os.path.relpath(entry, kernel_dir)
                        entry_dst_name = entry_name_fn(entry)
                        install_task.append((src, entry_dst_name))
                else:
                    install_task.append((src, dst))

            for src_path, dst_path in install_task:
                install_cmd = "install -m 0644 -D %s %s" \
                              % (os.path.join(kernel_dir, src_path),
                                 os.path.join(part_rootfs_dir, dst_path))
                exec_cmd(install_cmd)

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

        boot_files = get_bitbake_var("IMAGE_EFI_BOOT_FILES")
        if boot_files:
            cls._deploy_additional_boot_files(boot_files, kernel_dir, part_rootfs_dir)

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
