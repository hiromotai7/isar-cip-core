#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2020-2022
#
# Authors:
#  Quirin Gylstorff <quirin.gylstorff@siemens.com>
#  Jan Kiszka <jan.kiszka@siemens.com>
#
# SPDX-License-Identifier: MIT


inherit dpkg-raw

DEBIAN_DEPENDS = "initramfs-tools"
DEBIAN_CONFLICTS = "initramfs-verity-hook"

SRC_URI += "file://abrootfs.hook \
            file://abrootfs.script"

ABROOTFS_IMAGE_RECIPE ?= "cip-core-image"

# This is defined in image.bbclass which cannot be used in a package recipe.
# However, we need to use IMAGE_FULLNAME to pick up any extensions of it.
IMAGE_FULLNAME ??= "${ABROOTFS_IMAGE_RECIPE}-${DISTRO}-${MACHINE}"

IMAGE_UUID_ENV_FILE = "${DEPLOY_DIR_IMAGE}/${IMAGE_FULLNAME}.uuid.env"

do_install[depends] += "${ABROOTFS_IMAGE_RECIPE}:do_generate_image_uuid"
do_install[cleandirs] += " \
    ${D}/usr/share/initramfs-tools/hooks \
    ${D}/usr/share/abrootfs \
    ${D}/usr/share/initramfs-tools/scripts/local-top"

do_install() {
    if [ -f "${IMAGE_UUID_ENV_FILE}" ]; then
        install -m 0600 "${IMAGE_UUID_ENV_FILE}" "${D}/usr/share/abrootfs/image-uuid.env"
    else
        bberror "Did not find ${IMAGE_UUID_ENV_FILE}. initramfs will not be build correctly!"
    fi
    install -m 0755 "${WORKDIR}/abrootfs.script" \
        "${D}/usr/share/initramfs-tools/scripts/local-top/abrootfs"
    install -m 0755 "${WORKDIR}/abrootfs.hook" \
        "${D}/usr/share/initramfs-tools/hooks/abrootfs"
}
