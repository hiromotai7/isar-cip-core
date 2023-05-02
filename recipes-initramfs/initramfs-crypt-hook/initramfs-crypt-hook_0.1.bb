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
DEBIAN_DEPENDS = "initramfs-tools, cryptsetup, \
    awk, openssl, libtss2-esys-3.0.2-0 | libtss2-esys0, \
    libtss2-rc0 | libtss2-esys0, libtss2-mu0 | libtss2-esys0, e2fsprogs"

CLEVIS_DEPEND = ", clevis-luks, jose, bash, luksmeta, file, libpwquality-tools"

DEBIAN_DEPENDS:append:buster = "${CLEVIS_DEPEND}, libgcc-7-dev"
DEBIAN_DEPENDS:append:bullseye = "${CLEVIS_DEPEND}"
DEBIAN_DEPENDS:append = ", systemd (>= 251) | clevis-tpm2"

CRYPT_BACKEND:buster = "clevis"
CRYPT_BACKEND:bullseye = "clevis"
CRYPT_BACKEND = "systemd"

SRC_URI += "file://encrypt_partition.env.tmpl \
            file://encrypt_partition.${CRYPT_BACKEND}.script \
            file://encrypt_partition.${CRYPT_BACKEND}.hook \
            file://pwquality.conf"

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
    ${D}/usr/share/initramfs-tools/scripts/local-bottom \
    ${D}/usr/lib/encrypt_partition"
do_install() {
    install -m 0600 "${WORKDIR}/encrypt_partition.env" "${D}/usr/share/encrypt_partition/encrypt_partition.env"
    install -m 0755 "${WORKDIR}/encrypt_partition.${CRYPT_BACKEND}.script" \
        "${D}/usr/share/initramfs-tools/scripts/local-bottom/encrypt_partition"
    install -m 0755 "${WORKDIR}/encrypt_partition.${CRYPT_BACKEND}.hook" \
        "${D}/usr/share/initramfs-tools/hooks/encrypt_partition"
    install -m 0644 "${WORKDIR}/pwquality.conf" "${D}/usr/share/encrypt_partition/pwquality.conf"
}
