#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2020-2024
#
# Authors:
#  Quirin Gylstorff <quirin.gylstorff@siemens.com>
#
# SPDX-License-Identifier: MIT

inherit dpkg-raw
DEBIAN_DEPENDS = "initramfs-tools, cryptsetup, \
    awk, openssl, libtss2-esys-3.0.2-0 | libtss2-esys0, \
    libtss2-rc0 | libtss2-esys0, libtss2-mu0 | libtss2-esys0, e2fsprogs, tpm2-tools"

CLEVIS_DEPEND = ", clevis-luks, jose, bash, luksmeta, file, libpwquality-tools"

DEBIAN_DEPENDS:append:buster = "${CLEVIS_DEPEND}, libgcc-7-dev"
DEBIAN_DEPENDS:append:bullseye = "${CLEVIS_DEPEND}"
DEBIAN_DEPENDS:append = "${@encryption_dependency(d)}"

def encryption_dependency(d):
    crypt_backend = d.getVar('CRYPT_BACKEND')
    if crypt_backend == 'clevis':
        clevis_depends= d.getVar('CLEVIS_DEPEND')
        return f"{clevis_depends}, clevis-tpm2"
    elif crypt_backend == 'systemd':
        return ", systemd (>= 251)"
    else:
        bb.error("unkown cryptbackend defined")

def add_additional_clevis_hooks(d):
    base_distro_code_name = d.getVar('BASE_DISTRO_CODENAME') or ""
    crypt_backend = d.getVar('CRYPT_BACKEND') or ""
    if crypt_backend != 'clevis':
        return ""
    if base_distro_code_name == "buster":
        return f"encrypt_partition.{crypt_backend}.buster.hook"
    else:
        return f"encrypt_partition.{crypt_backend}.bullseye_or_later.hook"

CRYPT_BACKEND:buster = "clevis"
CRYPT_BACKEND:bullseye = "clevis"
CRYPT_BACKEND = "systemd"

SRC_URI += "file://encrypt_partition.env.tmpl \
            file://encrypt_partition.script \
            file://encrypt_partition.${CRYPT_BACKEND}.script \
            file://mount_crypt_partitions.script \
            file://encrypt_partition.${CRYPT_BACKEND}.hook \
            file://pwquality.conf"
ADDITIONAL_CLEVIS_HOOK = "${@add_additional_clevis_hooks(d)}"
SRC_URI += "${@ 'file://' + d.getVar('ADDITIONAL_CLEVIS_HOOK') if d.getVar('ADDITIONAL_CLEVIS_HOOK')else ''}"
# CRYPT_PARTITIONS elements are <partition-label>:<mountpoint>:<reencrypt or format>
CRYPT_PARTITIONS ??= "home:/home:reencrypt var:/var:reencrypt"
# CRYPT_CREATE_FILE_SYSTEM_CMD contains the shell command to create the filesystem
# in a newly formatted LUKS Partition
CRYPT_CREATE_FILE_SYSTEM_CMD ??= "/usr/sbin/mke2fs -t ext4"
# Timeout for creating / re-encrypting partitions on first boot
CRYPT_SETUP_TIMEOUT ??= "600"
# Watchdog to service during the initial setup of the crypto partitions
INITRAMFS_WATCHDOG_DEVICE ??= "/dev/watchdog"
# clevis needs tpm hash algorithm type
CRYPT_HASH_TYPE ??= "sha256"
CRYPT_KEY_ALGORITHM ??= "ecc"
CRYPT_ENCRYPTION_OPTIONAL ??= "false"

TEMPLATE_VARS = "CRYPT_PARTITIONS CRYPT_CREATE_FILE_SYSTEM_CMD \
    CRYPT_SETUP_TIMEOUT INITRAMFS_WATCHDOG_DEVICE CRYPT_HASH_TYPE \
    CRYPT_KEY_ALGORITHM CRYPT_ENCRYPTION_OPTIONAL"
TEMPLATE_FILES = "encrypt_partition.env.tmpl"

do_install[cleandirs] += " \
    ${D}/usr/share/initramfs-tools/hooks \
    ${D}/usr/share/encrypt_partition \
    ${D}/usr/share/initramfs-tools/scripts/local-top \
    ${D}/usr/share/initramfs-tools/scripts/local-bottom"

do_install() {
    install -m 0600 "${WORKDIR}/encrypt_partition.env" "${D}/usr/share/encrypt_partition/encrypt_partition.env"
    install -m 0755 "${WORKDIR}/encrypt_partition.script" \
        "${D}/usr/share/initramfs-tools/scripts/local-top/encrypt_partition"
    install -m 0755 "${WORKDIR}/encrypt_partition.${CRYPT_BACKEND}.script" \
        "${D}/usr/share/encrypt_partition/encrypt_partition_tpm2"
    install -m 0755 "${WORKDIR}/mount_crypt_partitions.script" \
        "${D}/usr/share/initramfs-tools/scripts/local-bottom/mount_decrypted_partition"
    install -m 0755 "${WORKDIR}/encrypt_partition.${CRYPT_BACKEND}.hook" \
        "${D}/usr/share/initramfs-tools/hooks/encrypt_partition"
    if [ -f "${WORKDIR}"/"${ADDITIONAL_CLEVIS_HOOK}" ]; then
        install -m 0755 "${WORKDIR}"/"${ADDITIONAL_CLEVIS_HOOK}" \
            "${D}/usr/share/initramfs-tools/hooks/encrypt_partition.${BASE_DISTRO_CODENAME}"
    fi

    install -m 0644 "${WORKDIR}/pwquality.conf" "${D}/usr/share/encrypt_partition/pwquality.conf"
}
