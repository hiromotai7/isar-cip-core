#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2024
#
# Authors:
#  Jan Kiszka <jan.kiszka@siemens.com>
#
# SPDX-License-Identifier: MIT
#

IMAGER_INSTALL:erofs += "erofs-utils"

EROFS_EXCLUDE_DIRS ?= ""
EROFS_CONTENT ?= "${PP_ROOTFS}"
EROFS_CREATION_ARGS ?= "-z lz4hc,12"

python __anonymous() {
    exclude_directories = d.getVar('EROFS_EXCLUDE_DIRS').split()
    if len(exclude_directories) == 0:
        return
    # Use regex to exclude only content of the directory.
    # This allows to use the directory as a mount point.
    for dir in exclude_directories:
        args += " --exclude-regex {dir}/.* ".format(dir=dir)
    d.appendVar('EROFS_CREATION_ARGS', args)
}

IMAGE_CMD:erofs[depends] = "${PN}:do_transform_template"
IMAGE_CMD:erofs() {
    ${SUDO_CHROOT} /bin/mkfs.erofs \
        '${IMAGE_FILE_CHROOT}' '${EROFS_CONTENT}' \
        ${EROFS_CREATION_ARGS}
}
