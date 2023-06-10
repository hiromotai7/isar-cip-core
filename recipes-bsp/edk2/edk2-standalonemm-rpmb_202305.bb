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
    https://github.com/MIPI-Alliance/public-mipi-sys-t/archive/${SRCREV-mipisyst}.tar.gz;name=mipisyst;subdir=${S} \
    https://github.com/openssl/openssl/archive/refs/tags/${PV-openssl}.tar.gz;name=openssl;subdir=${S} \
    file://rules \
    "
SRC_URI[sha256sum] = "5f6c18cf1068089d669fbe81dab2325f8bf7b1298b192c276490b65e2edbbd94"
SRC_URI[edk2-platforms.sha256sum] = "31257160ac51a4a5f63db92d26482d6a005286ed040dafe89d01f0ee906b111e"
SRC_URI[brotli.sha256sum] = "6d6cacce05086b7debe75127415ff9c3661849f564fe2f5f3b0383d48aa4ed77"
SRC_URI[mipisyst.sha256sum] = "9fda3b9a78343ab2be6f06ce6396536e7e065abac29b47c8eb2e42cbb4c4f00b"
SRC_URI[openssl.sha256sum] = "b1270f044e36452e15d1f2e18b702691a240b0445080282f2c7daaea8704ec5e"

# according to edk2 submodules
SRCREV-brotli = "f4153a09f87cbb9c826d8fc12c74642bb2d879ea"
SRCREV-mipisyst = "370b5944c046bab043dd8b133727b2135af7747a"

# revision closest to edk2 release
SRCREV-edk2-platforms = "b71f2bda9e4fc183068eef5d1d90a631181a2506"

PV-openssl = "OpenSSL_1_1_1t"

DEBIAN_BUILD_DEPENDS = "bash, python3:native, dh-python, uuid-dev:native"

do_prepare_build() {
    deb_debianize

    ln -sf edk2-edk2-stable${PV} ${S}/edk2
    ln -sf edk2-platforms-${SRCREV-edk2-platforms} ${S}/edk2-platforms

    rm -rf ${S}/edk2/BaseTools/Source/C/BrotliCompress/brotli
    ln -s ../../../../../brotli-${SRCREV-brotli} ${S}/edk2/BaseTools/Source/C/BrotliCompress/brotli

    rm -rf ${S}/edk2/MdeModulePkg/Library/BrotliCustomDecompressLib/brotli
    ln -s ../../../../brotli-${SRCREV-brotli} ${S}/edk2/MdeModulePkg/Library/BrotliCustomDecompressLib/brotli

    rm -rf ${S}/edk2/MdePkg/Library/MipiSysTLib/mipisyst
    ln -s ../../../../public-mipi-sys-t-${SRCREV-mipisyst} ${S}/edk2/MdePkg/Library/MipiSysTLib/mipisyst

    rm -rf ${S}/edk2/CryptoPkg/Library/OpensslLib/openssl
    ln -s ../../../../openssl-${PV-openssl} ${S}/edk2/CryptoPkg/Library/OpensslLib/openssl

    echo "Build/MmStandaloneRpmb/RELEASE_GCC5/FV/BL32_AP_MM.fd /usr/lib/edk2/" > \
        ${S}/debian/edk2-standalonemm-rpmb.install
}
