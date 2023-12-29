#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2020-2023
#
# Authors:
#  Quirin Gylstorff <quirin.gylstorff@siemens.com>
#
# SPDX-License-Identifier: MIT

# This class generates the sw-description from the variables:
SWU_IMAGES ??= ""
SWU_FILES ??= ""
SWU_SCRIPTS ??= ""

# Each image/file/script added by these variables needs to be specified in
# the following format. See also
# https://sbabic.github.io/swupdate/sw-description.html

# EXAMPLE configuration
# the following configuration installs a new rootfs,kernel and
# bootloader to the target
#
# Add the root filesystem image:
# SWU_IMAGES += "rootfs"
# SWU_IMAGE_rootfs[filename] = "${SWU_ROOTFS_PARTITION_NAME}"
# SWU_IMAGE_rootfs[device] = "C:BOOT0:linux.efi->${ABROOTFS_PART_UUID_A},C:BOOT1:linux.efi->${ABROOTFS_PART_UUID_B}"
# SWU_IMAGE_rootfs[type] = "roundrobin"
# SWU_IMAGE_rootfs[compressed] = "zlib"
# SWU_IMAGE_rootfs[properties] += "subtype:image"
# SWU_IMAGE_rootfs[properties] += "configfilecheck:/etc/os-release@not_match@IMAGE_UUID=${TARGET_IMAGE_UUID}"
#
# Add the kernel file
# SWU_FILES += "kernel"
# SWU_FILE_kernel[filename] = "linux.efi"
# SWU_FILE_kernel[path] = "linux.efi"
# SWU_FILE_kernel[type] = "roundrobin"
# SWU_FILE_kernel[device] = "C:BOOT0:linux.efi->BOOT0,C:BOOT1:linux.efi->BOOT1"
# SWU_FILE_kernel[filesystem] = "vfat"
# SWU_FILE_kernel[properties] = "subtype:kernel"
#
# Add the bootloader file
# SWU_FILES += "ebg"
# SWU_FILE_ebg[filename] = "bootx64.efi"
# SWU_FILE_ebg[path] = "EFI/BOOT/bootx64.efi"
# SWU_FILE_ebg[device] = "/dev/disk/by-uuid/4321-DCBA"
# SWU_FILE_ebg[filesystem] = "vfat"
#
# Add some preinstallation script
# SWU_SCRIPTS += "preinstall"
# SWU_SCRIPT_preinstall[filename] = "preinstall.sh"
# SWU_SCRIPT_preinstall[type] = "preinstall.sh"

def add_flag_to_dict(d, var, flagname, dictionary):
    flag = d.getVarFlag(var,  flagname) or ""
    if flag:
        dictionary.update({flagname: flag})


def add_list_to_dict(d, var_entry, flagname, dictionary):
    flag = d.getVarFlag(var_entry,  flagname) or ""
    if flag:
        entries = flag.split()
        result = {}
        for entry in entries:
            key, value = entry.split(':')
            result.update({key: value})
        dictionary.update({flagname: result})


def get_entries_from_var(d, entries_var, entry_var):
    entries = (d.getVar(entries_var) or "").split()
    if not entries:
        return None
    # see https://sbabic.github.io/swupdate/sw-description.html
    # sha256 is added directly
    # data, encrypted and hook are currently not supported
    possible_image_flags = ("filename", "type",
                            "device",
                            "compressed", "name", "version",
                            "install-if-different",
                            "install-if-higher",
                             "installed-directly",
                            "offset", )
    possible_file_flags = ("filename", "type",
                           "device",
                           "compressed", "name", "version",
                           "install-if-different",
                           "install-if-higher",
                           "filesystem", "path", "preserve-attributes")
    possible_script_flags = ("filename", "type")
    entry_var_to_flags = {
            "SWU_IMAGE": possible_image_flags,
            "SWU_FILE": possible_file_flags,
            "SWU_SCRIPT": possible_script_flags,
    }

    entry_list = []
    for entry in entries:
        elem = {}
        var_entry = f"{entry_var}_{entry}"
        for flag in entry_var_to_flags[entry_var]:
            add_flag_to_dict(d, var_entry, flag, elem)
            if flag == "filename":
                # filename handling
                filename = elem.get("filename")
                if not filename:
                    bb.warn(f"No filename for {var_entry}. Entry will not be added to sw-description")
                    continue
                elem.update({ "sha256": f"{filename}-sha256" })

        add_list_to_dict(d, var_entry, "properties", elem)
        entry_list.append(elem)
    # we return a tuple as this allow to generate json or libconfig
    # swuconfigurations
    return tuple(entry_list)


def generate_sw_description(d):
    sw_description = {}
    # in theory we can have multiple boards
    # this is currently not support
    board = {}
    hw_compat = d.getVar('SWU_HW_COMPAT')
    if hw_compat:
        hw_entries = ', '. join(['"' + h + '"' for h in hw_compat.split()])
        board.update({"hardware-compatibility": hw_entries})
    #   Images
    sw_images = get_entries_from_var(d, "SWU_IMAGES", "SWU_IMAGE")
    if sw_images:
        board.update({"images": sw_images})
    #   Files
    sw_files = get_entries_from_var(d, "SWU_FILES", "SWU_FILE")
    if sw_files:
        board.update({"files": sw_files})
    #   Scripts
    sw_scripts = get_entries_from_var(d, "SWU_SCRIPTS", "SWU_SCRIPT")
    if sw_scripts:
        board.update({"scripts": sw_scripts})

    boardname = d.getVar("SWU_BOARD_NAME")
    if boardname and hw_compat:
        software.update({boardname: board})
    else:
        software = board

    swu_version = d.getVar('SWU_VERSION')
    name = d.getVar('SWU_NAME')
    reboot = d.getVar('SWU_REBOOT')
    transition_marker = d.get('SWU_BOOTLOADER_TRANSITION_MARKER')

    software.update({'version': swu_version, 'name': name})
    if reboot:
        software.update({'reboot': reboot, })
    if transition_marker:
        software.update({'bootloader_transaction_marker':  transition_marker, })


    sw_description.update({"software": software})

    return sw_description


covert_to_libconfig () {
    if [ -e '${WORKDIR}/${SWU_DESCRIPTION_FILE}.json' ]; then
        rm -f '${WORKDIR}/${SWU_DESCRIPTION_FILE}'
        imager_run -p -d ${PP_WORK} -u root <<'EOIMAGER'
    jsontolibconf '${PP_WORK}/${SWU_DESCRIPTION_FILE}.json' --output_file '${PP_WORK}/${SWU_DESCRIPTION_FILE}'
EOIMAGER
    fi
    sudo chown -R $(id -u):$(id -g) '${WORKDIR}/${SWU_DESCRIPTION_FILE}'
}

IMAGER_BUILD_DEPS += "jsontolibconf"
INSTALL_write_sw_description += "jsontolibconf"

do_write_sw_description[network] = "${TASK_USE_SUDO}"
python do_write_sw_description () {
    import json
    import os
    workdir = d.getVar("WORKDIR")
    sw_desc_file = d.getVar("SWU_DESCRIPTION_FILE")
    swu_files = (d.getVar('SWU_IMAGES'), d.getVar('SWU_FILES'), d.getVar('SWU_SCRIPTS'))
    if os.path.exists(f"{workdir}/{sw_desc_file}.tmpl") and \
        [x for x in swu_files if x is not None]:
        bb.warn(f"{sw_desc_file}.tmpl template exists. \
                sw-description will not be be generate from variables \
                SWU_IMAGES, SWU_FILES and SWU_SCRIPTS")
        pass
    sw_description = generate_sw_description(d)

    with open(f"{workdir}/{sw_desc_file}.json","w") as sw_desc_fd:
        json.dump(sw_description, sw_desc_fd, indent=2)
    bb.build.exec_func("covert_to_libconfig", d)
}

IMAGE_SRC_URI:swu:remove = "file://${SWU_DESCRIPTION_FILE}.tmpl"
IMAGE_TEMPLATE_FILES:swu:remove = "${SWU_DESCRIPTION_FILE}.tmpl"

addtask do_write_sw_description after do_generate_image_uuid before do_transform_template
