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

# find the file defined by INITRAMFS_DATA_RESET_MARKER in
# INITRAMFS_DATA_RESET_MARKER_STORAGE_DEVICE. Important
# this function does not work with disk encryption.
INITRAMFS_DATA_RESET_DETECT_MARKER ?= "detect-marker-file"

# if this file exists execute a data reset for the given
# list of reset targets.
INITRAMFS_DATA_RESET_MARKER ?= "/var/.data-reset"
# use labels as crypt setup replaces the label links if
# an partition is encrypted
INITRAMFS_DATA_RESET_MARKER_STORAGE_DEVICE ??= "/dev/disk/by-label/var"

# list of partitions by label
INITRAMFS_DATA_RESET_DEVICES ??= "/dev/disk/by-label/var"

SRC_URI += " \
    file://local-bottom-complete \
    file://reset-env.tmpl \
    file://${INITRAMFS_DATA_RESET_DETECT_MARKER} \
    file://hook"

TEMPLATE_FILES += "reset-env.tmpl"
TEMPLATE_VARS += " INITRAMFS_DATA_RESET_MARKER \
                   INITRAMFS_DATA_RESET_MARKER_STORAGE_DEVICE \
                   INITRAMFS_DATA_RESET_DEVICES"

DEBIAN_DEPENDS .= ", coreutils, util-linux"

HOOK_COPY_EXECS = "mountpoint findmnt mktemp rm find rmdir basename"

do_install[cleandirs] += "${D}/usr/share/data-reset/"
do_install:prepend() {
    install -m 0755 "${WORKDIR}/reset-env" \
        "${D}/usr/share/data-reset/reset-env"
    install -m 0755 "${WORKDIR}/${INITRAMFS_DATA_RESET_DETECT_MARKER}" \
        "${D}/usr/share/data-reset/data_reset_marker"
}
