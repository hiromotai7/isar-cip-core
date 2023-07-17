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

require swupdate-certificates.inc

SWU_SIGN_CERT = "${BASE_DISTRO_CODENAME}/PkKek-1-snakeoil.pem"

DEBIAN_CONFLICTS = "swupdate-certificates"
