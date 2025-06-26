# Encrypted Partitions

By adding the recipe `initramfs-crypt-hook` to the initramfs build user defined partitions will be
encrypted during first boot. The encrypted partition is a LUKS partition and uses a TPM to secure the
passphrase on the device.

> :exclamation:**IMPORTANT**
> All selected partitions are encrypted on first boot. In order to avoid the leakage of secrets
> the disk encryption must occur in a secure environment.

## Requirements

Testing with qemu-amd64 requires the package `swtpm`. Under Debian/Ubuntu this can be installed

``` shell
apt-get install swtpm
```

## TPM2 protected LUKS passphrase

The recipe `initramfs-crypt-hook` uses `systemd-cryptenroll` (Debian 12 and later)
or `clevis` (Debian 10 and Debian 11) to enroll a TPM2 protected LUKS passphrase.
The procedure for storing a key is described in [systemd/src/shared/tpm2-util.c](https://github.com/systemd/systemd/blob/0254e4d66af7aa893b31b2326335ded5dde48b51/src/shared/tpm2-util.c#L1395).

## How to build an QEMU image with TPM encryption
An example for qemu-amd64 can be build with by selecting the option after calling:

```
./kas-container menu
```
or by adding using the following command line build:

```
./kas-container build kas-cip.yml:kas/board/qemu-amd64.yml:kas/opt/ebg-swu.yml:kas/opt/encrypt-data.yml
```
## initramfs-crypt-hook configuration

The initramfs-crypt-hook recipe has the following variables which can be overwritten during image build:
- CRYPT_PARTITIONS
- CRYPT_CREATE_FILE_SYSTEM_CMD

### CRYPT_PARTITIONS

The variable `CRYPT_PARTITIONS` contains the information which partition shall be encrypted where to mount it.
Each entry uses the schema `<partition-identifier>:<mountpoint>:<reencrypt | format | noencrypt>`.
- The `partition-idenitifer` is used to identify the partition on the disk, it can contain a partition label, partition UUID or absolute path to the partition device, e.g. `/dev/sda`.
- The `mountpoint` is used mount the decrypted partition in the root file system
- `reencrypt` uses `cryptsetup reencrypt` to encrypt the exiting content of the partition. This reduces the partition by 32MB and the file system by a similar amount
- `format` creates a empty LUKS partition and creates a file system defined with the shell command given in `CRYPT_CREATE_FILE_SYSTEM_CMD`
- `noencrypt` will not try to encrypt the partition if it isn't encrypted already, but will open it if it is. See the section [Encrypting the shared partition via an update](#### Encrypting the shared partition via an update) for more information

#### Encrypted root file system

To encrypt the root file system the variable `CRYPT_PARTITIONS` needs to be set to:
```
CRYPT_PARTITIONS = "${ABROOTFS_PART_UUID_A}::reencrypt ${ABROOTFS_PART_UUID_B}::reencrypt"
```
The mountpoint is empty as the root partition is mounted  by a seperate initramfs hook.
Both partitions are encrypted during first boot. The initramfs hook opens `${ABROOTFS_PART_UUID_A}` and `${ABROOTFS_PART_UUID_B}`
during boot.

#### Encrypting the shared partition via an update

With the following requirements, special handling is necessary:

- A/B update scheme is used.
- Both slots have a shared volume that needs to be encrypted as well.
- The system in the field is currently unencrypted, and encryption should be added via an update.
- When the update fails, the fallback system needs to deal with an encrypted data partition.

In this case, the fallback system needs to support an encrypted shared data partition but would not encrypt it on its own. For this, the `noencrypt` flag can be used.

The data partition in the fallback system will have the `noencrypt` flag set, while the update system will set the flag to `reencrypt`. This will handle the following case:

- Unencrypted system on slot A is running; the shared data partition has set the `noencrypt` flag and is not encrypted.
- Update for enabling encryption is applied to slot B, where the shared data partition has the `reencrypt` flag.
- System reboots to slot B, encrypting the shared data partition.
- Update fails at a later point and is not blessed; system reboots into the fallback system on slot A.
- Fallback system now needs to be able to use the shared data partition.

### CRYPT_CREATE_FILE_SYSTEM_CMD

The variable `CRYPT_CREATE_FILE_SYSTEM_CMD` contains the command to create a new file system on a newly
encrypted partition. The Default (`mke2fs -t ext4`) creates an ext4 partition.

# Convert clevis based encryption to systemd-cryptenroll
## Prerequisites
The following packages are necessary to convert a clevis based encryption to a systemd-cryptenroll
based encryption:
 - clevis-luks
 - clevis-tpm2
 - cryptsetup
 - jq

## steps to convert clevis to systemd
The following script shows how to enroll a systemd-tpm2 token with a existing clevis based encryption:
```bash
export device=/dev/sda6
export keyslot=$(sudo cryptsetup luksDump "$device" --dump-json-metadata | jq -c '.tokens.[] | select( .type == "clevis") | .keyslots | first' | head -n1)
if [ -n "$keyslot" ]; then
  export PASSWORD=$(clevis luks pass -d "$device" -s"$keyslot")
  systemd-cryptenroll --tpm2-device="$tpm_device" --tpm2-pcrs=7 "$device"
fi
```
# TPM2 based encryption on generic x86

For a generic x86 platform with TPM2  module the build can be started with:

```bash
kas-container menu
```

The TPM2 module should support:
 - a sha256 pcr bar with the ecc algorithm.

If only a sha1 pcr bar is avaiable the variable `CRYPT_HASH_TYPE` needs to be set to `sha1`.
