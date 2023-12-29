#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2023
#
# Authors:
#  Quirin Gylstorff <quirin.gylstorff@siemens.com>
#
# SPDX-License-Identifier: MIT
#

inherit image_uuid
inherit read-only-rootfs
inherit ${@'' if d.getVar('BASE_DISTRO_CODENAME') == 'buster' else 'sw-description-generator'}

SWU_IMAGES += "rootfs"
SWU_IMAGE_rootfs[filename] = "${SWU_ROOTFS_PARTITION_NAME}"
SWU_IMAGE_rootfs[device] = "C:BOOT0:linux.efi->${ABROOTFS_PART_UUID_A},C:BOOT1:linux.efi->${ABROOTFS_PART_UUID_B}"
SWU_IMAGE_rootfs[type] = "roundrobin"
SWU_IMAGE_rootfs[compressed] = "zlib"
SWU_IMAGE_rootfs[properties] += "subtype:image"
SWU_IMAGE_rootfs[properties] += "configfilecheck:/etc/os-release@not_match@IMAGE_UUID=${TARGET_IMAGE_UUID}"

SWU_FILES += "kernel"
SWU_FILE_kernel[filename] = "linux.efi"
SWU_FILE_kernel[path] = "linux.efi"
SWU_FILE_kernel[type] = "roundrobin"
SWU_FILE_kernel[device] = "C:BOOT0:linux.efi->BOOT0,C:BOOT1:linux.efi->BOOT1"
SWU_FILE_kernel[filesystem] = "vfat"
SWU_FILE_kernel[properties] = "subtype:kernel"

EFI_BOOTLOADER_NAME = "${@efi_bootloader_name(d)}"
SWU_ADDITIONAL_FILES += "${@d.getVar('EFI_BOOTLOADER_NAME') if bb.utils.to_boolean(d.getVar('SWU_EBG_UPDATE')) else ''}"

SWU_FILES += "${@'ebg' if bb.utils.to_boolean(d.getVar('SWU_EBG_UPDATE')) else ''}"
SWU_FILE_ebg[filename] = "${EFI_BOOTLOADER_NAME}"
SWU_FILE_ebg[path] = "EFI/BOOT/${EFI_BOOTLOADER_NAME}"
SWU_FILE_ebg[device] = "${SWU_EFI_BOOT_DEVICE}"
SWU_FILE_ebg[filesystem] = "vfat"
SWU_FILE_kernel[properties] = "atomic-install:true"

SWU_SIGNED ?= "1"

IMAGE_INSTALL += " swupdate"

IMAGE_INSTALL += " swupdate-handler-roundrobin"
