#
# CIP Core, generic profile
#
# Copyright (c) Siemens, 2025
#
# Authors:
#  Jan Kiszka <jan.kiszka@siemens.com>
#
# SPDX-License-Identifier: MIT
#

require linux-cip-common.inc

def get_commit(d):
    try:
        return bb.fetch2.get_srcrev(d).replace('AUTOINC+', '')
    except bb.fetch2.FetchError:
        return ""

KERNEL_MAJOR_MINOR := "${@d.getVar('PV').split('-')[0]}"

BRANCH := "${@ \
    'linux-' + d.getVar('PV').split('-')[0] + '.y-cip' + \
    ('-rt' if d.getVar('KERNEL_NAME') == 'cip-rt' and \
              d.getVar('KERNEL_MAJOR_MINOR') in ['4.4', '4.19', '5.10', '6.1'] else '') \
    }"

PV .= "${@'-g' + get_commit(d)}"

SRC_URI += "git://git.kernel.org/pub/scm/linux/kernel/git/cip/linux-cip.git;protocol=https;branch=${BRANCH};name=cip-kernel"
SRCREV_FORMAT = "cip-kernel"
SRCREV_cip-kernel = "${AUTOREV}"

S = "${WORKDIR}/git"
