# IEC-62443-4-2 CR 4.1 Information Confidentiality
This document describes how CIP Platform uses the `cryptsetup` package to comply the Information Confidentiality requirements for Data-at-rest.

This document serves as a supplement to the [README.security-testing.md](doc/README.security-testing.md) document.

## Purpose and Aim
- This document is aim to used as reference only;

- CIP users are encouraged to employ `cryptsetup` to create secure encrypted storage to load/store their confidential data-at-rest.

## Objective
- `cryptsetup` package is used to comply the Information Confidentiality requirements for Data-at-rest;

- `cryptsetup` package is included in the recipe [cip-core-image-security.bb](recipes-core/images/cip-core-image-security.bb);

- `cryptsetup` package description itself can be see on [Debian package viewer](https://packages.debian.org/bullseye/cryptsetup);

- `cryptsetup` package here is verified on CIP security image based on Debian Bullseye with Kernel 5.10.y-CIP on qemu Arm64.

## Pre-requisite
- To prepare for `cryptsetup` package usage, please see [README.security-testing.md](doc/README.security-testing.md).

## How to employ `cryptsetup` package on qemu Arm64
Precaution: This section is refer to [Encrypting devices with LUKS mode](https://wiki.archlinux.org/title/dm-crypt/Device_encryption#Encrypting_devices_with_LUKS_mode) part of:
- _[dm-crypt/Device encryption](https://wiki.archlinux.org/title/dm-crypt/Device_encryption) - ArchLinux's Wiki covers how to manually utilize `dm-crypt` from the command line to encrypt a system._

Make sure to select "qemu Arm64", "Debian Bullseye", "Kernel 5.10.y-CIP", "Security Image" on KAS menu before building and/or running target images, see [README.md](README.md).

`start-qemu.sh` will prepare second (virtual) storage called `secure-image.img`, mounted to `/dev/vdb`.

This second storage will be used for `cryptsetup`/LUKS partitions.

### Formatting/Partitioning the RAW disk using fdisk
`secure-image.img` storage that mounted to `/dev/vdb` need to be prepared using `fdisk`.
```
root@demo:~# fdisk /dev/vdb

Welcome to fdisk (util-linux 2.36.1).
Changes will remain in memory only, until you decide to write them.
Be careful before using the write command.

Device does not contain a recognized partition table.
Created a new DOS disklabel with disk identifier 0x487ced68.

Command (m for help): p
Disk /dev/vdb: 2 GiB, 2147483648 bytes, 4194304 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0x487ced68

Command (m for help): n
Partition type
   p   primary (0 primary, 0 extended, 4 free)
   e   extended (container for logical partitions)
Select (default p): p
Partition number (1-4, default 1):
First sector (2048-4194303, default 2048):
Last sector, +/-sectors or +/-size{K,M,G,T,P} (2048-4194303, default 4194303):

Created a new partition 1 of type 'Linux' and of size 2 GiB.

Command (m for help): w
The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks.
```

### Formatting LUKS partitions
In order to setup a partition as an encrypted LUKS partition execute:
```
root@demo:~# cryptsetup luksFormat /dev/vdb1

WARNING!
========
This will overwrite data on /dev/vdb1 irrevocably.

Are you sure? (Type 'yes' in capital letters): YES
Enter passphrase for /dev/vdb1:
Verify passphrase:
```

### Unlocking/Mapping LUKS partitions with device mapper
Once the LUKS partitions have been created, they can then be unlocked.
```
root@demo:~# cryptsetup open /dev/vdb1 root
Enter passphrase for /dev/vdb1:
```

Once opened, the root partition device address would be `/dev/mapper/root` instead of the partition (e.g. `/dev/vdb1`).

In order to write encrypted data into the partition it must be accessed through the device mapped name. The first step of access will typically be to create a file system. For example:
```
root@demo:~# mkfs -t ext4 /dev/mapper/root
mke2fs 1.46.2 (28-Feb-2021)
Creating filesystem with 519936 4k blocks and 130048 inodes
Filesystem UUID: 492deb7c-6487-422f-a039-72bb1cc9981c
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912

Allocating group tables: done
Writing inode tables: done
Creating journal (8192 blocks): done
Writing superblocks and filesystem accounting information: done
```

The device `/dev/mapper/root` can then be mounted like any other partition.

For example, `/dev/mapper/root` can be mounted to `/mnt/myluks` directory, as:
```
root@demo:~# mkdir /mnt/myluks
root@demo:~# mount /dev/mapper/root /mnt/myluks
```

To close the LUKS container, unmount the partition and then unmapping LUKS partitions:
```
root@demo:~# umount /mnt/myluks
root@demo:~# cryptsetup close root
```

## References and Relates
- [dm-crypt](https://gitlab.com/cryptsetup/cryptsetup/-/wikis/DMCrypt) - The project homepage.

- [cryptsetup](https://gitlab.com/cryptsetup/cryptsetup) - The LUKS homepage and [FAQ](https://gitlab.com/cryptsetup/cryptsetup/-/wikis/FrequentlyAskedQuestions) - the main and foremost help resource.

- [Partitioning with fdisk](https://tldp.org/HOWTO/Partition/fdisk_partitioning.html) -  The guideline how to partition hard drive with the `fdisk` utility.

## Advanced Topics
- [dm-crypt/Encrypting an entire system](https://wiki.archlinux.org/title/dm-crypt/Encrypting_an_entire_system) - ArchLinux's Wiki covers examples of common scenarios of full system encryption with `dm-crypt`.
