#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2022-2023
#
# Authors:
# Jan Kiszka <jan.kiszka@...>
#
# SPDX-License-Identifier: MIT
#

inherit dpkg-gbp

SRC_URI += " \
 git://salsa.debian.org/python-team/packages/python-shtab.git;protocol=https;branch=main \
 "

# modify for debian buster build
SRC_URI:append:buster = " \
 file://0001-Lower-requirements-on-setuptools.patch"

SRCREV ="3cdca7c8f4ead23c194c4e8a84e2631989e26b3c"

# We don't have pristine-tar in this tree hence use this option
GBP_EXTRA_OPTIONS = "--git-no-pristine-tar"

DEB_BUILD_PROFILES = "nocheck"
DEB_BUILD_OPTIONS = "nocheck"
