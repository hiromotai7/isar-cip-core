#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2020-2024
#
# Authors:
#  Christian Storm <christian.storm@siemens.com>
#  Quirin Gylstorff <quirin.gylstorff@siemens.com>
#  Felix Moessbauer <felix.moessbauer@siemens.com>
#
# SPDX-License-Identifier: MIT

inherit template

SWU_ROOTFS_TYPE ?= "squashfs"
SWU_ROOTFS_NAME ?= "${IMAGE_FULLNAME}"
# compression type as defined by swupdate (zlib or zstd). Set to empty string to disable compression
SWU_COMPRESSION_TYPE ?= "zlib"
SWU_ROOTFS_PARTITION_NAME ?= "${SWU_ROOTFS_NAME}.${SWU_ROOTFS_TYPE}${@get_swu_compression_type(d)}"
SWU_VERSION ?= "0.2"
SWU_NAME ?= "cip software update"
# space separated list of supported hw. Leave empty to leave out
SWU_HW_COMPAT ?= ""

SWU_EBG_UPDATE ?= ""
SWU_EFI_BOOT_DEVICE ?= "/dev/disk/by-uuid/4321-DCBA"
SWU_BOOTLOADER ??= "ebg"
SWU_DESCRIPITION_FILE_BOOTLOADER ??= "${SWU_DESCRIPTION_FILE}-${SWU_BOOTLOADER}"

SWU_IMAGE_FILE ?= "${IMAGE_FULLNAME}"
SWU_DESCRIPTION_FILE ?= "sw-description"
SWU_ADDITIONAL_FILES ?= "linux.efi ${SWU_ROOTFS_PARTITION_NAME}"
SWU_SIGNED ??= ""
SWU_SIGNATURE_EXT ?= "sig"
SWU_SIGNATURE_TYPE ?= "cms"

SWU_BUILDCHROOT_IMAGE_FILE ?= "${@os.path.basename(d.getVar('SWU_IMAGE_FILE'))}"

IMAGE_TYPEDEP:swu = "${SWU_ROOTFS_TYPE}${@get_swu_compression_type(d)}"
IMAGER_BUILD_DEPS:swu += "${@'swupdate-certificates-key' if bb.utils.to_boolean(d.getVar('SWU_SIGNED')) else ''}"
IMAGER_INSTALL:swu += "cpio ${@'openssl swupdate-certificates-key' if bb.utils.to_boolean(d.getVar('SWU_SIGNED')) else ''}"
IMAGE_INSTALL += "${@'swupdate-certificates' if bb.utils.to_boolean(d.getVar('SWU_SIGNED')) else ''}"


IMAGE_SRC_URI:swu = "file://${SWU_DESCRIPTION_FILE}.tmpl"
IMAGE_SRC_URI:swu += "file://${SWU_DESCRIPITION_FILE_BOOTLOADER}.tmpl"
IMAGE_TEMPLATE_FILES:swu = "${SWU_DESCRIPTION_FILE}.tmpl"
IMAGE_TEMPLATE_FILES:swu += "${SWU_DESCRIPITION_FILE_BOOTLOADER}.tmpl"
IMAGE_TEMPLATE_VARS:swu = " \
    SWU_ROOTFS_PARTITION_NAME \
    TARGET_IMAGE_UUID \
    ABROOTFS_PART_UUID_A \
    ABROOTFS_PART_UUID_B \
    SWU_HW_COMPAT_NODE \
    SWU_COMPRESSION_NODE \
    SWU_VERSION \
    SWU_NAME \
    SWU_FILE_NODES \
    SWU_BOOTLOADER_FILE_NODE \
    "

# TARGET_IMAGE_UUID needs to be generated before completing the template
addtask do_transform_template after do_generate_image_uuid

python(){
    cmds = d.getVar("SWU_EXTEND_SW_DESCRIPTION")
    if cmds is None or not cmds.strip():
        return
    cmds = cmds.split()
    for cmd in cmds:
        bb.build.exec_func(cmd, d)
}

SWU_EXTEND_SW_DESCRIPTION += "add_swu_hw_compat"
python add_swu_hw_compat(){
    # create SWU_HW_COMPAT_NODE based on list of supported hw
    hw_compat = d.getVar('SWU_HW_COMPAT')
    if hw_compat:
        hw_entries = ', '. join(['"' + h + '"' for h in hw_compat.split()])
        d.setVar('SWU_HW_COMPAT_NODE',
            'hardware-compatibility: [ ' + hw_entries +' ];')
    else:
        d.setVar('SWU_HW_COMPAT_NODE', '')
}

SWU_EXTEND_SW_DESCRIPTION += "add_swu_compression"
python add_swu_compression(){
    # create SWU_COMPRESSION_NODE node if compression is enabled
    calgo = d.getVar('SWU_COMPRESSION_TYPE')
    if calgo:
        d.setVar('SWU_COMPRESSION_NODE', 'compressed = "' + calgo + '";')
    else:
        d.setVar('SWU_COMPRESSION_NODE', '')
}

# convert between swupdate compressor name and imagetype extension
def get_swu_compression_type(d):
    swu_ct = d.getVar('SWU_COMPRESSION_TYPE')
    if not swu_ct:
        return ''
    swu_to_image = {'zlib': '.gz', 'zstd': '.zst'}
    if swu_ct not in swu_to_image:
        bb.fatal('requested SWU_COMPRESSION_TYPE is not supported by swupdate')
    return swu_to_image[swu_ct]

# This imagetype is neither machine nor distro specific. Hence, we cannot
# use paths in FILESOVERRIDES. Manual modifications of this variable are
# discouradged and hard to implement. Instead, we register this path explicitly.
# We append to the path, so locally provided config files are preferred
FILESEXTRAPATHS:append = ":${LAYERDIR_cip-core}/recipes-core/images/swu"

do_image_swu[depends] += "${PN}:do_transform_template"
do_image_swu[stamp-extra-info] = "${DISTRO}-${MACHINE}"
do_image_swu[cleandirs] += "${WORKDIR}/swu ${WORKDIR}/swu-${SWU_BOOTLOADER}"
IMAGE_CMD:swu() {
    rm -f '${DEPLOY_DIR_IMAGE}/${SWU_IMAGE_FILE}'*.swu
    cp '${WORKDIR}/${SWU_DESCRIPTION_FILE}' '${WORKDIR}/swu/${SWU_DESCRIPTION_FILE}'
    if [ -f '${WORKDIR}/${SWU_DESCRIPITION_FILE_BOOTLOADER}' ]; then
        cp '${WORKDIR}/${SWU_DESCRIPITION_FILE_BOOTLOADER}' '${WORKDIR}/swu-${SWU_BOOTLOADER}/${SWU_DESCRIPTION_FILE}'
    fi

    for swu_file in "${WORKDIR}"/swu*; do
        swu_file_base=$(basename $swu_file)
        # Create symlinks for files used in the update image
        for file in ${SWU_ADDITIONAL_FILES}; do
            if grep -q "$file" "${WORKDIR}/$swu_file_base/${SWU_DESCRIPTION_FILE}"; then
                if [ -e "${WORKDIR}/$file" ]; then
                    ln -s "${PP_WORK}/$file" "${WORKDIR}/$swu_file_base/$file"
                else
                    ln -s "${PP_DEPLOY}/$file" "${WORKDIR}/$swu_file_base/$file"
                fi
            fi
        done

        # Prepare for signing
        export sign='${@'x' if bb.utils.to_boolean(d.getVar('SWU_SIGNED')) else ''}'
        export swu_file_base
        # create a exetension to differ between swus
        swu_file_extension=""
        if [ "$swu_file_base" != "swu" ]; then
            swu_file_extension=${swu_file_base#swu}
        fi
        export swu_file_extension
        imager_run -p -d ${PP_WORK} -u root <<'EOIMAGER'
            # Fill in file check sums
            for file in ${SWU_ADDITIONAL_FILES}; do
                sed -i "s:$file-sha256:$(sha256sum "${PP_WORK}/$swu_file_base/"$file | cut -f 1 -d " "):g" \
                    "${PP_WORK}/$swu_file_base/${SWU_DESCRIPTION_FILE}"
            done
            cd "${PP_WORK}/$swu_file_base"
            for file in "${SWU_DESCRIPTION_FILE}" ${SWU_ADDITIONAL_FILES}; do
                if [ "$file" = "${SWU_DESCRIPTION_FILE}" ] || \
                    grep -q "$file" "${PP_WORK}/$swu_file_base/${SWU_DESCRIPTION_FILE}"; then
                    # Set file timestamps for reproducible builds
                    if [ -n "${SOURCE_DATE_EPOCH}" ]; then
                        touch -d@"${SOURCE_DATE_EPOCH}" "$file"
                    fi
                    echo "$file"
                    if [ -n "$sign" -a "${SWU_DESCRIPTION_FILE}" = "$file" ]; then
                        sign-swu "$file" "$file.${SWU_SIGNATURE_EXT}"
                        # Set file timestamps for reproducible builds
                        if [ -n "${SOURCE_DATE_EPOCH}" ]; then
                            touch -d@"${SOURCE_DATE_EPOCH}" "$file.${SWU_SIGNATURE_EXT}"
                        fi
                        echo "$file.${SWU_SIGNATURE_EXT}"
                    fi
                fi
            done | cpio -ovL --reproducible -H crc > "${PP_DEPLOY}/${SWU_IMAGE_FILE}$swu_file_extension.swu"
EOIMAGER
    done
}

python do_check_swu_partition_uuids() {
    for u in ['A', 'B']:
        if not d.getVar('ABROOTFS_PART_UUID_' + u):
            bb.fatal('ABROOTFS_PART_UUID_' + u + ' not set')
}

addtask check_swu_partition_uuids before do_image_swu
