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
# This implements the 'efibootguard-boot' source plugin class for 'wic'
#
# AUTHORS
# Tom Zanussi <tom.zanussi (at] linux.intel.com>
# Claudius Heine <ch (at] denx.de>
# Andreas Reichel <andreas.reichel.ext (at] siemens.com>
# Christian Storm <christian.storm (at] siemens.com>

import os
import fnmatch
import sys
import logging

msger = logging.getLogger('wic')

from wic.pluginbase import SourcePlugin
from wic.misc import exec_cmd, get_bitbake_var, BOOTDD_EXTRA_SPACE

class EfibootguardBootPlugin(SourcePlugin):
    """
    Create EFI Boot Guard partition hosting the
    environment file plus Kernel files.
    """

    name = 'efibootguard-boot'

    @classmethod
    def do_prepare_partition(cls, part, source_params, creator, cr_workdir,
                             oe_builddir, deploy_dir, kernel_dir,
                             rootfs_dir, native_sysroot):
        """
        Called to do the actual content population for a partition, i.e.,
        populate an EFI Boot Guard environment partition plus Kernel files.
        """

        kernel_image = get_bitbake_var("KERNEL_IMAGE")
        if not kernel_image:
            msger.warning("KERNEL_IMAGE not set. Use default:")
            kernel_image = "vmlinuz"
        boot_image = kernel_image

        initrd_image = get_bitbake_var("INITRD_DEPLOY_FILE")
        if not initrd_image:
            msger.warning("INITRD_DEPLOY_FILE not set\n")
            initrd_image = "initrd.img"
        bootloader = creator.ks.bootloader

        dtb_files = (get_bitbake_var("DTB_FILES") or '').split()

        deploy_dir = get_bitbake_var("DEPLOY_DIR_IMAGE")
        if not deploy_dir:
            msger.error("DEPLOY_DIR_IMAGE not set, exiting\n")
            exit(1)
        creator.deploy_dir = deploy_dir

        wdog_timeout = get_bitbake_var("WDOG_TIMEOUT")
        if not wdog_timeout:
            msger.error("Specify watchdog timeout for \
            efibootguard in local.conf with WDOG_TIMEOUT=")
            exit(1)

        boot_files = source_params.get("files", "").split(' ')
        unified_kernel = source_params.get("unified-kernel") or 'y'
        cmdline = bootloader.append or ''
        if unified_kernel == 'y':
            boot_image = cls._create_unified_kernel_image(rootfs_dir,
                                                          cr_workdir,
                                                          cmdline,
                                                          deploy_dir,
                                                          kernel_image,
                                                          initrd_image,
                                                          dtb_files,
                                                          source_params)
            boot_files.append(boot_image)
        else:
            if dtb_files:
                msger.error("DTB_FILES specified while unified kernel is disabled\n")
                exit(1)
            root_dev = source_params.get("root", None)
            if not root_dev:
                msger.error("Specify root in source params")
                exit(1)
            root_dev = root_dev.replace(":", "=")

            cmdline += " root=%s rw " % root_dev
            boot_files.append(kernel_image)
            boot_files.append(initrd_image)
            cmdline += "initrd=%s" % initrd_image if initrd_image else ""

        part_rootfs_dir = "%s/disk/%s.%s" % (cr_workdir,
                                             part.label, part.lineno)
        create_dir_cmd = "install -d %s" % part_rootfs_dir
        exec_cmd(create_dir_cmd)

        cwd = os.getcwd()
        os.chdir(part_rootfs_dir)
        config_cmd = '/usr/bin/bg_setenv -f . -k "C:%s:%s" %s -r %s -w %s' \
            % (
                part.label.upper(),
                boot_image,
                '-a "%s"' % cmdline if unified_kernel != 'y' else '',
                source_params.get("revision", 1),
                wdog_timeout
            )
        exec_cmd(config_cmd, True)
        os.chdir(cwd)

        boot_files = list(filter(None, boot_files))
        for boot_file in boot_files:
            if os.path.isfile("%s/%s" % (kernel_dir, kernel_image)):
                install_cmd = "install -m 0644 %s/%s %s/%s" % \
                    (kernel_dir, boot_file, part_rootfs_dir, boot_file)
                exec_cmd(install_cmd)
            else:
                msger.error("file %s not found in directory %s",
                            boot_file, kernel_dir)
                exit(1)
        cls._create_img(part_rootfs_dir, part, cr_workdir,
                        native_sysroot, oe_builddir)

    @classmethod
    def _create_img(cls, part_rootfs_dir, part, cr_workdir,
                    native_sysroot, oe_builddir):
        # Write label as utf-16le to EFILABEL file
        with open("%s/EFILABEL" % part_rootfs_dir, 'wb') as filedescriptor:
            filedescriptor.write(part.label.upper().encode("utf-16le"))

        bootimg = "%s/%s.%s.img" % (cr_workdir, part.label, part.lineno)

        part.prepare_rootfs_msdos(bootimg, cr_workdir, oe_builddir,
                                  part_rootfs_dir, native_sysroot, None)
        du_cmd = "du -Lbks %s" % bootimg
        bootimg_size = int(exec_cmd(du_cmd).split()[0])

        part.size = bootimg_size
        part.source_file = bootimg

    @classmethod
    def _create_unified_kernel_image(cls, rootfs_dir, cr_workdir, cmdline,
                                     deploy_dir, kernel_image, initrd_image,
                                     dtb_files, source_params):
        rootfs_path = rootfs_dir.get('ROOTFS_DIR')
        efiarch = get_bitbake_var("EFI_ARCH")
        if not efiarch:
            msger.error("Bitbake variable 'EFI_ARCH' not set, exiting\n")
            exit(1)
        libarch = get_bitbake_var("EFI_LIB_ARCH")
        if not libarch:
            msger.error("Bitbake variable 'EFI_LIB_ARCH' not set, exiting\n")
            exit(1)

        efistub = "{rootfs_path}/usr/lib/{libpath}/efibootguard/kernel-stub{efiarch}.efi"\
            .format(rootfs_path=rootfs_path,
                    libpath=libarch,
                    efiarch=efiarch)
        uefi_kernel_name = "linux.efi"
        uefi_kernel_file = "{deploy_dir}/{uefi_kernel_name}"\
            .format(deploy_dir=deploy_dir, uefi_kernel_name=uefi_kernel_name)
        kernel = "{deploy_dir}/{kernel_image}"\
            .format(deploy_dir=deploy_dir, kernel_image=kernel_image)
        initrd = "{deploy_dir}/{initrd_image}"\
            .format(deploy_dir=deploy_dir, initrd_image=initrd_image)
        cmd = 'bg_gen_unified_kernel {efistub} {kernel} {uefi_kernel_file} \
            -c "{cmdline}" -i {initrd}'.format(
                cmdline=cmdline,
                kernel=kernel,
                initrd=initrd,
                efistub=efistub,
                uefi_kernel_file=uefi_kernel_file)
        if dtb_files:
            for dtb in dtb_files:
                cmd += ' -d {deploy_dir}/{dtb_file}'.format(
                    deploy_dir=deploy_dir,
                    dtb_file=os.path.basename(dtb))
        exec_cmd(cmd, as_shell=True)

        cls._sign_file(signee=uefi_kernel_file, source_params=source_params)

        return uefi_kernel_name

    @classmethod
    def _sign_file(cls, signee, source_params):
        sign_script = source_params.get("signwith")
        if sign_script and os.path.exists(sign_script):
            msger.info("sign with script %s", sign_script)
            orig_signee = signee + ".unsigned"
            os.rename(signee, orig_signee)
            sign_cmd = "{sign_script} {orig_signee} {signee}"\
                .format(sign_script=sign_script, orig_signee=orig_signee,
                        signee=signee)
            exec_cmd(sign_cmd)
        elif sign_script and not os.path.exists(sign_script):
            msger.error("Could not find script %s", sign_script)
            exit(1)
