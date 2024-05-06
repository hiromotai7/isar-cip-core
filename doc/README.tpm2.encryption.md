# Encrypted Partitions

By adding the recipe `initramfs-crypt-hook` to the initramfs build user defined partitions will be
encrypted during first boot. The encrypted partition is a LUKS partition and uses a TPM to secure the
passphrase on the device.

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
Each entry uses the schema `<partition-label>:<mountpoint>:<reencrypt or format>`.
- The `partition-label` is used to identify the partition on the disk
- The `mountpoint` is used mount the decrypted partition in the root file system
- `reencrypt` uses `cryptsetup reencrypt` to encrypt the exiting content of the partition. This reduces the partition by 32MB and the file system by a similar amount
- `format` creates a empty LUKS partition and creates a file system defined with the shell command given in `CRYPT_CREATE_FILE_SYSTEM_CMD`

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
The following script shows how to enroll a systemd-tpm2 token with a existinng clevis based encryption:
```bash
export device=/dev/sda6
export keyslot=$(sudo cryptsetup luksDump "$device" --dump-json-metadata | jq -c '.tokens.[] | select( .type == "clevis") | .keyslots | first' | head -n1)
if [ -n "$keyslot" ]; then
  export PASSWORD=$(clevis luks pass -d "$device" -s"$keyslot")
  systemd-cryptenroll --tpm2-device="$tpm_device" --tpm2-pcrs=7 "$device"
fi
```
