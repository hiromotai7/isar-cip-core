#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2024
#
# Authors:
#  Quirin Gylstorff <quirin.gylstorff@siemens.com>
#
# SPDX-License-Identifier: MIT
#

IMAGE_INSTALL:append = " efibootguard libebgenv0"
IMAGER_INSTALL:wic:append = " efibootguard:${DISTRO_ARCH}"
WDOG_TIMEOUT ?= "60"
WICVARS += "WDOG_TIMEOUT KERNEL_IMAGE INITRD_DEPLOY_FILE DTB_FILES EFI_ARCH EFI_LIB_ARCH"
IMAGE_TYPEDEP:swu:append = " wic"

def distro_to_efi_arch(d):
    DISTRO_TO_EFI_ARCH = {
        "amd64": "x64",
        "arm64": "aa64",
        "armhf": "arm",
        "i386": "ia32",
        "riscv64": "riscv64"
    }
    distro_arch = d.getVar('DISTRO_ARCH')
    return DISTRO_TO_EFI_ARCH[distro_arch]

EFI_ARCH := "${@distro_to_efi_arch(d)}"

def distro_to_lib_arch(d):
    DISTRO_TO_LIB_ARCH = {
        "amd64": "x86_64-linux-gnu",
        "arm64": "aarch64-linux-gnu",
        "armhf": "arm-linux-gnueabihf",
        "i386": "i386-linux-gnu",
        "riscv64": "riscv64-linux-gnu",
    }
    distro_arch = d.getVar('DISTRO_ARCH')
    return DISTRO_TO_LIB_ARCH[distro_arch]

EFI_LIB_ARCH := "${@distro_to_lib_arch(d)}"
