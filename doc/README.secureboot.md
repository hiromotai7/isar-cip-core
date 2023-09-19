# EFI Boot Guard secure boot

This document describes how to generate a secure boot capable image with
[efibootguard](https://github.com/siemens/efibootguard).

## Description

The image build signs the EFI Boot Guard bootloader (bootx64.efi) and generates
a signed [unified kernel image](https://uapi-group.org/specifications/specs/unified_kernel_image).
A unified kernel image packs the kernel, initramfs and the kernel command-line
in one binary object. As the kernel command-line is immutable after the build
process, the previous selection of the root file system with a command-line parameter is no longer
possible. Therefore the selection of the root file-system occurs now in the initramfs.

The image uses an A/B partition layout to update the root file system. The sample implementation to
select the root file system generates a uuid and stores the id in /etc/os-release and in the initramfs.
During boot the initramfs compares its own uuid with the uuid stored in /etc/os-release of each rootfs.
If a match is found the rootfs is used for the boot.

## Adaptation for Images

### WIC
The following elements must be present in a wks file to create a secure boot capable image.

```
part --source efibootguard-efi  --sourceparams "signwith=<script or executable to sign the image>"
part --source efibootguard-boot --sourceparams "signwith=<script or executable to sign the image>"
```

#### Script or executable to sign the image

The wic plugins for the [bootloader](./scripts/lib/wic/plugins/source/efibootguard-efi.py)
and [boot partition](./scripts/lib/wic/plugins/source/efibootguard-boot.py) require an
executable or script with the following interface:
```
<script_name> <inputfile> <outputfile>
```
- script name: name and path of the script added with
`--sourceparams "signwith=/usr/bin/sign_secure_image.sh"` to the wic image
- inputfile: path and name of the file to be signed
- outputfile: path and name of the signed input

Supply the script name and path to wic by adding
`signwith=<path and name of the script to sign>"` to sourceparams of the partition.

### Existing key packages for signing an image

#### secure-boot-snakeoil

This package uses the snakeoil key and certificate from the ovmf package(0.0~20200229-2)
backported from Debian bullseye for signing the image.

#### secure-boot-key

This package takes a user-generated certificate and key adds them to the build system.
The following variable and steps are necessary to build a secure boot capable image:
- Set certification information to sign and verify the image with:
    - SB_CERT: The certificate to verify the signing process
    - SB_KEY: The private key of for the certificate

The files referred by SB_CERT and SB_KEY must be store in `recipes-devtools/secure-boot-secrets/files/`.

## Running in QEMU

Set up a secure boot test environment with [QEMU](https://www.qemu.org/)

### Prerequisites

- OVMF from edk2 release edk2-stable201911 or newer
  - This documentation was tested under Debian 11 with OVMF (2020.11-2+deb11u1) from Debian bullseye
- efitools for KeyTool.efi
  - This documentation was tested under Debian 11 with efitools (1.9.2-2~deb11u1) from Debian bullseye
- libnss3-tools

### Debian Snakeoil keys

The build copies the  Debian Snakeoil keys to the directory `./build/tmp/deploy/images/<machine>/OVMF.
You can use them as described in section [Start Image](#start-the-image).

### Generate Keys

#### Reuse existing keys

It is possible to use exiting keys like /usr/share/ovmf/PkKek-1-snakeoil.pem' from Debian
by executing the script  `scripts/generate-sb-db-from-existing-certificate.sh`, e.g.:
```
export SB_NAME=<name for the secureboot config>
export SB_KEYDIR=<location to store the database>
export INKEY=<secret key of the certificate>
export INCERT=<certificate>
export INNICK=<name of the certificate in the database>
scripts/generate-sb-db-from-existing-certificate.sh
```
This will create the directory `SB_KEYDIR` and will store the `${SB_NAME}certdb` with the given name.

Copy the used certificate and private key to `recipes-devtools/secure-boot-secrets/files/`

#### Generate keys

To generate the necessary keys and information to test secure-boot with QEMU
execute the script `scripts/generate_secure_boot_keys.sh`

##### Add Keys to OVMF
1. Create a folder and copy the generated keys and KeyTool.efi
(in Debian the file can be found at: /lib/efitools/x86_64-linux-gnu/KeyTool.efi) to the folder

```bash
mkdir secureboot-tools
cp -r keys secureboot-tools
cp /lib/efitools/x86_64-linux-gnu/KeyTool.efi secureboot-tools
```

2. Copy the file OVMF_VARS_4M.fd (in Debian the file can be found at /usr/share/OVMF/OVMF_VARS_4M.fd)
to the current directory. OVMF_VARS_4M.fd contains no keys can be instrumented for secureboot.
3. Start QEMU with the script scripts/start-efishell.sh

```bash
./scripts/start-efishell.sh secureboot-tools
```

4. Start the KeyTool.efi FS0:\KeyTool.efi and execute the the following steps:

```
          -> "Edit Keys"
             -> "The Allowed Signatures Database (db)"
                -> "Add New Key"
                -> Change/Confirm device
                -> Select "demoDB.esl" file
             -> "The Key Exchange Key Database (KEK)"
                -> "Add New Key"
                -> Change/Confirm device
                -> Select "demoKEK.esl" file
             -> "The Platform Key (PK)
                -> "Replace Key(s)"
                -> Change/Confirm device
                -> Select "demoPK.auth" file
```

5. quit QEMU

### Build image

Build the image with a signed EFI Boot Guard and unified kernel image
with the snakeoil keys by executing:

```bash
kas-container build kas-cip.yml:kas/board/qemu-amd64.yml:kas/opt/ebg-secure-boot-snakeoil.yml
```

For user-generated keys, create a new option file in the repository. This option file could look like this:

```yaml
header:
  version: 14
  includes:
   - kas/opt/ebg-swu.yml

local_conf_header:
  secure-boot-image: |
    IMAGE_FSTYPES = "wic"
    IMAGE_TYPEDEP:wic += "verity"
    SWU_ROOTFS_TYPE = "verity"
    WKS_FILE = "${MACHINE}-efibootguard-secureboot.wks.in"
    INITRAMFS_INSTALL:append = " initramfs-verity-hook"
    # abrootfs cannot be installed together with verity
    INITRAMFS_INSTALL:remove = "initramfs-abrootfs-hook"

  secure-boot: |
    IMAGER_BUILD_DEPS += "ebg-secure-boot-signer"
    IMAGER_INSTALL += "ebg-secure-boot-signer"

    # Use user-generated keys
    PREFERRED_PROVIDER_secure-boot-secrets = "secure-boot-key"

  secureboot_override: |
    OVERRIDES .= ":secureboot"

  user-keys: |
    SB_CERT = "demoDB.crt"
    SB_KEY = "demoDB.key"
```

Replace `demo` with the name of the user-generated certificates. The user-generated certificates
need to stored in the folder `recipes-devtools/ebg-secure-boot-secrets/files`.

Build the image with user-generated keys by executing the command:

```bash
kas-container build kas-cip.yml:kas/board/qemu-amd64.yml:<path to the new option>.yml
```

### Start the image

#### Debian snakeoil

Start the image with the following command:

```bash
SECURE_BOOT=y \
./start-qemu.sh amd64
```

The image configuration menu will set default values for start-qemu.sh for secureboot
and the following command is sufficient:

```bash
./start-qemu.sh amd64
```

#### User-generated keys
Start the image with the following command:

```bash
SECURE_BOOT=y \
OVMF_CODE=./build/tmp/deploy/images/qemu-amd64/OVMF/OVMF_CODE_4M.secboot.fd \
OVMF_VARS=<path to the modified OVMF_VARS.fd> \
./start-qemu.sh amd64
```

After boot check the dmesg for secure boot status like below:

```bash
root@demo:~# dmesg | grep Secure
[    0.008368] Secure boot enabled
```

In case of arm64 or armhf architectures, the secure boot status can be found in bootloader logs like below:

```bash
EFI stub: UEFI Secure Boot is enabled.
```
## Example: Update the image

For updating the image, the following steps are necessary:
- [Build the image with snakeoil keys](#build-image)
- save the generated swu `build/tmp/deploy/images/qemu-amd64/cip-core-image-cip-core-bullseye-qemu-amd64.swu` to /tmp
- modify the image for example, switch to the RT kernel as modification:

```bash
kas-container build kas-cip.yml:kas/board/qemu-amd64.yml:kas/opt/ebg-secure-boot-snakeoil.yml:kas/opt/rt.yml
```

- start the new target

```bash
SECURE_BOOT=y ./start-qemu.sh amd64
```

Copy the swu cip-core-image-cip-core-bullseye-qemu-amd64.swu to the running system

```bash
scp -P 22222 /tmp/cip-core-image-cip-core-bullseye-qemu-amd64.swu root@127.0.0.1:/home/
```

- check which partition is booted, e.g. with `lsblk`:

```bash
root@demo:~# lsblk
NAME           MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINT
sda              8:0    0     6G  0 disk
├─sda1           8:1    0  16.1M  0 part
├─sda2           8:2    0    32M  0 part
├─sda3           8:3    0    32M  0 part
├─sda4           8:4    0     1G  0 part
│ └─verityroot 252:0    0 110.9M  1 crypt /
├─sda5           8:5    0     1G  0 part
├─sda6           8:6    0   1.3G  0 part  /home
└─sda7           8:7    0   2.6G  0 part  /var
```

- install the swupdate and reboot the image

```bash
root@demo:~# swupdate -i /home/cip-core-image-cip-core-bullseye-qemu-amd64.swu`
root@demo:~# reboot
```

- check which partition is booted, e.g. with `lsblk`. The rootfs should have changed:

```bash
root@demo:~# lsblk
NAME           MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINT
sda              8:0    0     6G  0 disk
├─sda1           8:1    0  16.1M  0 part
├─sda2           8:2    0    32M  0 part
├─sda3           8:3    0    32M  0 part
├─sda4           8:4    0     1G  0 part
├─sda5           8:5    0     1G  0 part
│ └─verityroot 252:0    0 110.9M  1 crypt /
├─sda6           8:6    0   1.3G  0 part  /home
└─sda7           8:7    0   2.6G  0 part  /var
```
