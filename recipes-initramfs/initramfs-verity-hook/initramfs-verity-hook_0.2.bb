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

inherit dpkg-raw

SRC_URI += " \
    file://verity.hook \
    file://verity.script.tmpl \
    "

VERITY_BEHAVIOR_ON_CORRUPTION ?= "--restart-on-corruption"

TEMPLATE_FILES = "verity.script.tmpl"
TEMPLATE_VARS += "VERITY_BEHAVIOR_ON_CORRUPTION"

DEBIAN_DEPENDS = "initramfs-tools, cryptsetup"
DEBIAN_CONFLICTS = "initramfs-abrootfs-hook"

VERITY_IMAGE_RECIPE ?= "cip-core-image"

# This is defined in image.bbclass which cannot be used in a package recipe.
# However, we need to use IMAGE_FULLNAME to pick up any extensions of it.
IMAGE_FULLNAME ??= "${VERITY_IMAGE_RECIPE}-${DISTRO}-${MACHINE}"

VERITY_ENV_FILE = "${DEPLOY_DIR_IMAGE}/${IMAGE_FULLNAME}.verity.env"

do_install[depends] += "${VERITY_IMAGE_RECIPE}:do_image_verity"
do_install[cleandirs] += " \
    ${D}/usr/share/initramfs-tools/hooks \
    ${D}/usr/share/verity-env \
    ${D}/usr/share/initramfs-tools/scripts/local-top"

do_install() {
    # Insert the veritysetup commandline into the script
    if [ -f "${VERITY_ENV_FILE}" ]; then
        install -m 0600 "${VERITY_ENV_FILE}" "${D}/usr/share/verity-env/verity.env"
    else
        bberror "Did not find ${VERITY_ENV_FILE}. initramfs will not be build correctly!"
    fi
    install -m 0755 "${WORKDIR}/verity.script" \
        "${D}/usr/share/initramfs-tools/scripts/local-top/verity"
    install -m 0755 "${WORKDIR}/verity.hook" \
        "${D}/usr/share/initramfs-tools/hooks/verity"
}

addtask install after do_transform_template
