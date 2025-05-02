#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2025
#
# Authors:
#  Quirin Gylstorff <quirin.gylstorff@siemens.com>
#
# SPDX-License-Identifier: MIT

require recipes-initramfs/initramfs-hook/hook.inc
DESCRIPTION = "Delete the content of the given Devices"

# find the file defined by INITRAMFS_FACTORY_RESET_MARKER in
# INITRAMFS_FACTORY_RESET_MARKER_STORAGE_DEVICE. Important
# this function does not work with disk encryption.
FACTORY_RESET_DETECT_MARKER ?= "detect-marker-file"

# list of partitions by label
INITRAMFS_FACTORY_RESET_DEVICES ??= "/dev/disk/by-partlabel/var"
INITRAMFS_FACTORY_RESET_LUKS_FORMAT_TYPE ??= "ext4"
SRC_URI += " \
    file://reset-env.tmpl \
    file://local-top \
    file://${FACTORY_RESET_DETECT_MARKER} \
    file://hook"

TEMPLATE_FILES += "reset-env.tmpl"
TEMPLATE_VARS += " INITRAMFS_FACTORY_RESET_DEVICES \
                   INITRAMFS_FACTORY_RESET_LUKS_FORMAT_TYPE"

RDEPENDS = "factory-reset-helper"
DEBIAN_DEPENDS .= ", coreutils, util-linux, e2fsprogs, btrfs-progs, awk, factory-reset-helper"
DEBIAN_DEPENDS:append:encrypt-partitions = ", tpm2-tools"
HOOK_COPY_EXECS = "mountpoint findmnt mktemp rmdir basename \
                   mke2fs mkfs.btrfs awk blkid rm get-factory-reset.sh \
                   chattr grep"
HOOK_COPY_EXECS:append:encrypt-partitions = " tpm2_clear"

do_install[cleandirs] += "${D}/usr/share/factory-reset/"
do_install:prepend() {
    install -m 0755 "${WORKDIR}/reset-env" \
        "${D}/usr/share/factory-reset/reset-env"
    install -m 0755 "${WORKDIR}/${FACTORY_RESET_DETECT_MARKER}" \
        "${D}/usr/share/factory-reset/factory_reset_marker"
}
