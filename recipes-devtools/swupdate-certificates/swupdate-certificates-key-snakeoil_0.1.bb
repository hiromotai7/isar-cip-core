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
DEPENDS += "swupdate-certificates-snakeoil"
DEBIAN_DEPENDS += "swupdate-certificates-snakeoil"

require swupdate-certificates-key.inc

SWU_SIGN_KEY = "${BASE_DISTRO_CODENAME}/PkKek-1-snakeoil.key"

DEBIAN_CONFLICTS = "swupdate-certificates-key"
