#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2021-2024
#
# Authors:
#  Quirin Gylstorff <quirin.gylstorff@siemens.com>
#
# SPDX-License-Identifier: MIT
#

require recipes-initramfs/initramfs-hook/hook.inc

SRC_URI += " \
    file://hook \
    file://local-top-complete.tmpl \
    "

VERITY_BEHAVIOR_ON_CORRUPTION ?= "--restart-on-corruption"

TEMPLATE_FILES += "local-top-complete.tmpl"
TEMPLATE_VARS += "VERITY_BEHAVIOR_ON_CORRUPTION"

DEBIAN_DEPENDS = "initramfs-tools, cryptsetup"
DEBIAN_CONFLICTS = "initramfs-abrootfs-hook"

HOOK_ADD_MODULES = "dm_mod dm_verity"
HOOK_COPY_EXECS = "veritysetup dmsetup"

VERITY_IMAGE_RECIPE ?= "cip-core-image"

# This is defined in image.bbclass which cannot be used in a package recipe.
# However, we need to use IMAGE_FULLNAME to pick up any extensions of it.
IMAGE_FULLNAME ??= "${VERITY_IMAGE_RECIPE}-${DISTRO}-${MACHINE}"

VERITY_ENV_FILE = "${DEPLOY_DIR_IMAGE}/${IMAGE_FULLNAME}.verity.env"

do_install[depends] += "${VERITY_IMAGE_RECIPE}:do_image_verity"
do_install[cleandirs] += "${D}/usr/share/verity-env"

do_install:append() {
    # Insert the veritysetup commandline into the script
    if [ -f "${VERITY_ENV_FILE}" ]; then
        install -m 0600 "${VERITY_ENV_FILE}" "${D}/usr/share/verity-env/verity.env"
    else
        bberror "Did not find ${VERITY_ENV_FILE}. initramfs will not be build correctly!"
    fi
}

addtask install after do_transform_template
