#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2022 - 2023
#
# Authors:
#  Jan Kiszka <jan.kiszka@siemens.com>
#  Quirin Gylstorff <quirin.gylstorff@siemens.com>
#
# SPDX-License-Identifier: MIT
#

inherit dpkg-raw

SRC_URI += " \
    file://overlay.hook \
    file://overlay.script.tmpl \
    "

# The variable INITRAMFS_OVERLAY_PATHS contains the directories which are
# overlayed(lower dir).
INITRAMFS_OVERLAY_PATHS ??= "/etc"

# The variable INITRAMFS_OVERLAY_STORAGE_PATH designates the path were the
# changes to the overlayed directory are stored (upper dir). The initramfs
# also mounts the first directory after root to the
# INITRAMFS_OVERLAY_STORAGE_DEVICE.
INITRAMFS_OVERLAY_STORAGE_PATH ??= "/var/local"

# override this to switch to UUID or PARTUUID based mounts
INITRAMFS_OVERLAY_STORAGE_DEVICE ??= "/dev/disk/by-label/var"
INITRAMFS_OVERLAY_MOUNT_OPTION ??= "defaults,nodev,nosuid,noexec"

TEMPLATE_FILES = "overlay.script.tmpl"
TEMPLATE_VARS += " INITRAMFS_OVERLAY_STORAGE_PATH \
    INITRAMFS_OVERLAY_PATHS \
    INITRAMFS_OVERLAY_STORAGE_DEVICE \
    INITRAMFS_OVERLAY_MOUNT_OPTION"

DEBIAN_DEPENDS = "initramfs-tools, awk, coreutils, util-linux"

do_install[cleandirs] += " \
    ${D}/usr/share/initramfs-tools/hooks \
    ${D}/usr/share/initramfs-tools/scripts/local-bottom"

do_install() {
    install -m 0755 "${WORKDIR}/overlay.hook" \
        "${D}/usr/share/initramfs-tools/hooks/overlay"
    install -m 0755 "${WORKDIR}/overlay.script" \
        "${D}/usr/share/initramfs-tools/scripts/local-bottom/overlay"
}
