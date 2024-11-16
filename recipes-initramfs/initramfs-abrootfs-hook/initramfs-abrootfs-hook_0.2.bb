#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2020-2024
#
# Authors:
#  Quirin Gylstorff <quirin.gylstorff@siemens.com>
#  Jan Kiszka <jan.kiszka@siemens.com>
#
# SPDX-License-Identifier: MIT

require recipes-initramfs/initramfs-hook/hook.inc

DEBIAN_DEPENDS .= ", util-linux"
DEBIAN_CONFLICTS = "initramfs-verity-hook"

SRC_URI += " \
    file://hook \
    file://local-top-complete"

ABROOTFS_IMAGE_RECIPE ?= "cip-core-image"

HOOK_COPY_EXECS = "lsblk"

# This is defined in image.bbclass which cannot be used in a package recipe.
# However, we need to use IMAGE_FULLNAME to pick up any extensions of it.
IMAGE_FULLNAME ??= "${ABROOTFS_IMAGE_RECIPE}-${DISTRO}-${MACHINE}"

IMAGE_UUID_ENV_FILE = "${DEPLOY_DIR_IMAGE}/${IMAGE_FULLNAME}.uuid.env"

do_install[depends] += "${ABROOTFS_IMAGE_RECIPE}:do_generate_image_uuid"
do_install[cleandirs] += "${D}/usr/share/abrootfs"

do_install:append() {
    if [ -f "${IMAGE_UUID_ENV_FILE}" ]; then
        install -m 0600 "${IMAGE_UUID_ENV_FILE}" "${D}/usr/share/abrootfs/image-uuid.env"
    else
        bberror "Did not find ${IMAGE_UUID_ENV_FILE}. initramfs will not be build correctly!"
    fi
}
