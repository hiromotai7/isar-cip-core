#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2022-2023
#
# Authors:
#  Sven Schultschik <sven.schultschik@siemens.com>
#  Jan Kiszka <jan.kiszka@siemens.com>
#
# SPDX-License-Identifier: MIT
#

HOMEPAGE = "https://github.com/tianocore/edk2"
MAINTAINER = "Sven Schultschik <sven.schultschik@siemens.com>"

inherit dpkg

SRC_URI = " \
    https://github.com/tianocore/edk2/archive/refs/tags/edk2-stable${PV}.tar.gz;subdir=${S} \
    https://github.com/tianocore/edk2-platforms/archive/${SRCREV-edk2-platforms}.tar.gz;name=edk2-platforms;subdir=${S} \
    https://github.com/google/brotli/archive/${SRCREV-brotli}.tar.gz;name=brotli;subdir=${S} \
    https://github.com/openssl/openssl/archive/refs/tags/${PV-openssl}.tar.gz;name=openssl;subdir=${S} \
    file://rules \
    "
SRC_URI[sha256sum] = "b7276c0496bf4983265bf3f9886b563af1ae6e93aade91f4634ead2b1338d1b4"
SRC_URI[edk2-platforms.sha256sum] = "b0f5b6d832e4dcc1d47a98ae0560e0b955433e32e8ac6d12c946c66d5fa6f51a"
SRC_URI[brotli.sha256sum] = "6d6cacce05086b7debe75127415ff9c3661849f564fe2f5f3b0383d48aa4ed77"
SRC_URI[openssl.sha256sum] = "6b2d2440ced8c802aaa61475919f0870ec556694c466ebea460e35ea2b14839e"

# according to edk2 submodules
SRCREV-brotli = "f4153a09f87cbb9c826d8fc12c74642bb2d879ea"

# revision closest to edk2 release
SRCREV-edk2-platforms = "4ad557e494d8055f5ea16009d6e565cace6571d6"

PV-openssl = "OpenSSL_1_1_1n"

DEBIAN_BUILD_DEPENDS = "bash, python3:native, dh-python, uuid-dev:native"

do_prepare_build() {
    deb_debianize

    ln -sf edk2-edk2-stable${PV} ${S}/edk2
    ln -sf edk2-platforms-${SRCREV-edk2-platforms} ${S}/edk2-platforms

    rm -rf ${S}/edk2/BaseTools/Source/C/BrotliCompress/brotli
    ln -s ../../../../../brotli-${SRCREV-brotli} ${S}/edk2/BaseTools/Source/C/BrotliCompress/brotli

    rm -rf ${S}/edk2/MdeModulePkg/Library/BrotliCustomDecompressLib/brotli
    ln -s ../../../../brotli-${SRCREV-brotli} ${S}/edk2/MdeModulePkg/Library/BrotliCustomDecompressLib/brotli

    rm -rf ${S}/edk2/CryptoPkg/Library/OpensslLib/openssl
    ln -s ../../../../openssl-${PV-openssl} ${S}/edk2/CryptoPkg/Library/OpensslLib/openssl

    echo "Build/MmStandaloneRpmb/RELEASE_GCC5/FV/BL32_AP_MM.fd /usr/lib/edk2/" > \
        ${S}/debian/edk2-standalonemm-rpmb.install
}
