#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2022-2023
#
# Authors:
#  Jan Kiszka <jan.kiszka@siemens.com>
#
# SPDX-License-Identifier: MIT
#

inherit dpkg-gbp

SRC_URI += " \
    git://salsa.debian.org/python-team/packages/python-shtab.git;protocol=https;branch=main \
    "
# modify for debian bullseye build
SRC_URI_append_bullseye = " file://0001-Add-toml-as-a-dependency-package.patch"

# modify for debian buster build
#SRC_URI_append_buster = " \
#                        file://0002-Lower-requirements-on-setuptools.patch \
#                        file://0003-Lower-requirements-on-setuptools.patch"

SRCREV ="5650535ae4a1d34a21b55dc61e3e891d87a9712f"

# We don't have pristine-tar in this tree hence use this option
GBP_EXTRA_OPTIONS = "--git-no-pristine-tar"

DEB_BUILD_PROFILES = "nocheck"
DEB_BUILD_OPTIONS = "nocheck"
