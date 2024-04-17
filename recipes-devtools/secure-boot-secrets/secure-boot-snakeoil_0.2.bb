#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2022
#
# Authors:
#  Jan Kiszka <jan.kiszka@siemens.com>
#
# SPDX-License-Identifier: MIT
#

require secure-boot-secrets.inc

SB_KEY = "${BASE_DISTRO_CODENAME}/PkKek-1-snakeoil.key"
SB_CERT = "${BASE_DISTRO_CODENAME}/PkKek-1-snakeoil.pem"

DEBIAN_CONFLICTS = "secure-boot-key"
