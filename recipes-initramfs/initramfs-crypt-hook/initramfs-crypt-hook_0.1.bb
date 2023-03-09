#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2020-2023
#
# Authors:
#  Quirin Gylstorff <quirin.gylstorff@siemens.com>
#
# SPDX-License-Identifier: MIT

inherit dpkg-raw

DEBIAN_DEPENDS = "initramfs-tools, cryptsetup, systemd(>= 251), \
    awk, openssl, libtss2-esys-3.0.2-0, libtss2-rc0, libtss2-mu0, e2fsprogs"

SRC_URI += "file://encrypt_partition.hook \
            file://encrypt_partition.script \
            file://encrypt_partition.env.tmpl"

# CRYPT_PARTITIONS elements are <partition-label>:<mountpoint>:<reencrypt or format>
CRYPT_PARTITIONS ??= "home:/home:reencrypt var:/var:reencrypt"
# CRYPT_CREATE_FILE_SYSTEM_CMD contains the shell command to create the filesystem
# in a newly formatted LUKS Partition
CRYPT_CREATE_FILE_SYSTEM_CMD ??= "mke2fs -t ext4"

TEMPLATE_VARS = "CRYPT_PARTITIONS CRYPT_CREATE_FILE_SYSTEM_CMD"
TEMPLATE_FILES = "encrypt_partition.env.tmpl"

do_install[cleandirs] += " \
    ${D}/usr/share/initramfs-tools/hooks \
    ${D}/usr/share/encrypt_partition \
    ${D}/usr/share/initramfs-tools/scripts/local-bottom"
do_install() {
    install -m 0600 "${WORKDIR}/encrypt_partition.env" "${D}/usr/share/encrypt_partition/encrypt_partition.env"
    install -m 0755 "${WORKDIR}/encrypt_partition.script" \
        "${D}/usr/share/initramfs-tools/scripts/local-bottom/encrypt_partition"
    install -m 0755 "${WORKDIR}/encrypt_partition.hook" \
        "${D}/usr/share/initramfs-tools/hooks/encrypt_partition"
}
