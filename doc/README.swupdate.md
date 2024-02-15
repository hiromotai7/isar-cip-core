# SWUpdate support for the CIP core image

This document describes how to build and test the SWUpdate pre-integration for
isar-cip-core, targeting a QEMU x86 virtual machine.

Start with cloning the isar-cip-core repository:
```
host$ git clone https://gitlab.com/cip-project/cip-core/isar-cip-core.git
```
## SWUpdate Efibootguard update

:warning: **If the efibootguard binary is corrupted the system can no longer boot**

If you build a CIP Core image with SWUpdate support an additional swu will
be generated. This swu ends on `*-ebg.swu` and contains a sw-description to
update only efibootguard. SWUpdate will copy the file to a temporary location
and rename the binary in place to reduce the time the system can be destroyed
by a power failure. As FAT partitions have **no** atomic operations a small error
window is still possible.

If the variable `SWU_EBG_UPDATE` is set to `"1"` the update is also stored in
the `*.swu` file.

# Building and testing the CIP Core image

Set up `kas-container` as described in the [top-level README](../README.md).
Then build the image which will later serve as update package:
```
host$ ./kas-container build kas-cip.yml:kas/board/qemu-amd64.yml:kas/opt/ebg-swu.yml
```
Save the generated swu `build/tmp/deploy/images/qemu-amd64/cip-core-image-cip-core-bullseye-qemu-amd64.swu` into a separate folder (ex: /tmp).

Next, rebuild the image, switching to the RT kernel as modification:
```
host$ ./kas-container build kas-cip.yml:kas/board/qemu-amd64.yml:kas/opt/ebg-swu.yml:kas/opt/rt.yml
```

Now start the image which will contain the RT kernel:
```
host$ SWUPDATE_BOOT=y ./start-qemu.sh amd64
```

Copy `cip-core-image-cip-core-bullseye-qemu-amd64.swu` file from `tmp` folder into the running system:
```
host$ scp -P 22222 /tmp/cip-core-image-cip-core-bullseye-qemu-amd64.swu root@localhost:
```

## SWUpdate verification

Check which partition is booted, e.g. with lsblk:
```
root@demo:~# lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0    6G  0 disk
├─sda1   8:1    0 16.1M  0 part
├─sda2   8:2    0   32M  0 part
├─sda3   8:3    0   32M  0 part
├─sda4   8:4    0    1G  0 part /
├─sda5   8:5    0    1G  0 part
├─sda6   8:6    0  1.3G  0 part /home
└─sda7   8:7    0  2.6G  0 part /var
```

Also check that you are running the RT kernel:
```
root@demo:~# uname -a
Linux demo 4.19.233-cip69-rt24 #1 SMP PREEMPT RT Tue Apr 12 09:23:51 UTC 2022 x86_64 GNU/Linux
root@demo:~# ls /lib/modules
4.19.233-cip69-rt24
root@demo:~# cat /sys/kernel/realtime
1
```

Now apply swupdate and reboot
```
root@demo:~# swupdate -i cip-core-image-cip-core-bullseye-qemu-amd64.swu
root@demo:~# reboot
```

Check which partition is booted, e.g. with lsblk and the rootfs should have changed
```
root@demo:~# lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0    6G  0 disk
├─sda1   8:1    0 16.1M  0 part
├─sda2   8:2    0   32M  0 part
├─sda3   8:3    0   32M  0 part
├─sda4   8:4    0    1G  0 part
├─sda5   8:5    0    1G  0 part /
├─sda6   8:6    0  1.3G  0 part /home
└─sda7   8:7    0  2.6G  0 part /var
```

Check the active kernel:
```
root@demo:~# uname -a
Linux demo 4.19.235-cip70 #1 SMP Tue Apr 12 09:08:39 UTC 2022 x86_64 GNU/Linux
root@demo:~# ls /lib/modules
4.19.235-cip70
```

Check bootloader ustate after swupdate
```
root@demo:~# bg_printenv

----------------------------
 Config Partition #0 Values:
in_progress:      no
revision:         2
kernel:           C:BOOT0:linux.efi
kernelargs:
watchdog timeout: 60 seconds
ustate:           0 (OK)

user variables:



----------------------------
 Config Partition #1 Values:
in_progress:      no
revision:         3
kernel:           C:BOOT1:linux.efi
kernelargs:
watchdog timeout: 60 seconds
ustate:           2 (TESTING)

user variables:


```

If Partition #1 ustate is 2 (TESTING) then execute below command to confirm swupdate and the command will set ustate to "OK".
```
root@demo:~# bg_setenv -c
```

## SWUpdate rollback example

Build the image for swupdate with a service which causes kernel panic during system boot using below command:

```
host$ ./kas-container build kas-cip.yml:kas/board/qemu-amd64.yml:kas/opt/ebg-swu.yml:kas/opt/kernel-panic.yml
```
Save the generated swu `build/tmp/deploy/images/qemu-amd64/cip-core-image-cip-core-bullseye-qemu-amd64.swu` in a separate folder.
Then build the image without `kernel-panic.yml` recipe using below command:
```
host$ ./kas-container build kas-cip.yml:kas/board/qemu-amd64.yml:kas/opt/ebg-swu.yml
```

Start the target on QEMU:
```
host$ SWUPDATE_BOOT=y ./start-qemu.sh amd64
```

Copy `cip-core-image-cip-core-bullseye-qemu-amd64.swu` file from `tmp` folder into the running system:
```
host$ scp -P 22222 /tmp/cip-core-image-cip-core-bullseye-qemu-amd64.swu root@localhost:
```

Apply swupdate as below:
```
root@demo:~# swupdate -i cip-core-image-cip-core-bullseye-qemu-amd64.swu
```

Check bootloader ustate after swupdate. If the swupdate is successful then **revision number** should be **3** and status should be changed to **INSTALLED** for Partition #1.
```
root@demo:~# bg_printenv

----------------------------
 Config Partition #0 Values:
in_progress:      no
revision:         2
kernel:           C:BOOT0:linux.efi
kernelargs:
watchdog timeout: 60 seconds
ustate:           0 (OK)

user variables:



----------------------------
 Config Partition #1 Values:
in_progress:      no
revision:         3
kernel:           C:BOOT1:linux.efi
kernelargs:
watchdog timeout: 60 seconds
ustate:           1 (INSTALLED)

user variables:


```

Execute the reboot command.
```
root@demo:~# reboot
```

The new kernel should cause a kernel panic error.
The watchdog timer should expire and restart the VM (it will take 2 minutes due to an issue in.
The bootloader will then select the previous, working partition and boot from it.

Once the system is restarted, check the bootloader ustate.
If update is failed then **revision number** should be reduced to **0** and status should have changed to **FAILED** for Partition #1.
```
root@demo:~# bg_printenv

----------------------------
 Config Partition #0 Values:
in_progress:      no
revision:         2
kernel:           C:BOOT0:linux.efi
kernelargs:
watchdog timeout: 60 seconds
ustate:           0 (OK)

user variables:



----------------------------
 Config Partition #1 Values:
in_progress:      no
revision:         0
kernel:           C:BOOT1:linux.efi
kernelargs:
watchdog timeout: 60 seconds
ustate:           3 (FAILED)

user variables:


```
# Building and testing the CIP Core image for Delta Software Update

Set up `kas-container` as described in the [top-level README](../README.md), and then proceed with the following steps. Currently Delta Software Update is only supported for the root file system. 

The build steps are the same for Delta software update with both rdiff_image handler and delta handler.

First build an image using the following command:
```
host$ ./kas-container build kas-cip.yml:kas/board/qemu-amd64.yml:kas/opt/ebg-swu.yml:kas/opt/rt.yml
```

Copy the image artifacts genarated in `build/tmp/deploy/images/qemu-amd64/` into a separate folder (ex: ./image1).
```
host$ cp -r build/tmp/deploy/images/qemu-amd64/ ./image1
```
Currently, Delta Software Update is supported only for root file system.
Now, to create a delta update file, make some modifications to the root file system (ex: Add additional packages).
For this example, add the packages vim and nano (since the packages are not already included in the base image) to the image. This can be done by modifying the `recipes-core/images/cip-core-image.bb` file as shown below.
```
diff --git a/recipes-core/images/cip-core-image.bb b/recipes-core/images/cip-core-image.bb
index 0ec7220..f61ce23 100644
--- a/recipes-core/images/cip-core-image.bb
+++ b/recipes-core/images/cip-core-image.bb
@@ -14,6 +14,7 @@ inherit image
 ISAR_RELEASE_CMD = "git -C ${LAYERDIR_cip-core} describe --tags --dirty --always --match 'v[0-9].[0-9]*'"
 DESCRIPTION = "CIP Core image"

+IMAGE_PREINSTALL += "vim nano"
 IMAGE_INSTALL += "customizations"

 CIP_IMAGE_OPTIONS ?= ""
```

Now build an image with the above mentioned recipe changes with the following command:
```
host$ ./kas-container build kas-cip.yml:kas/board/qemu-amd64.yml:kas/opt/ebg-swu.yml
```

Copy the image artifacts genarated in `build/tmp/deploy/images/qemu-amd64/` into a separate folder (ex: ./image2).
```
host$ cp -r build/tmp/deploy/images/qemu-amd64/ ./image2
```

## Delta Software Update using rdiff_image handler 

Before proceeding, make sure the package `librsync2` is available in the system.

Under Debian/Ubuntu, librsync2 can be installed using the following command:  
```
host$ sudo apt-get install librsync2
```

For creating a delta update artifact for the rdiff_image handler, navigate to the `scripts` folder and run the `create_delta_swu.sh` file with the following commands:
```
host$ cd scripts
host$ sudo ./create_delta_swu.sh --type rdiff ../image1 ../image2
host$ cd ../
```

The `create_delta_swu.sh` creates a folder named `delta_update_artifacts` in the current directory which has the delta update artifacts. 

Now start the first image (which does not contain the packages vim and nano), run the following commands:
```
host$ sudo rm -r build/tmp/deploy/images/qemu-amd64/*
host$ cp -r ./image1/* build/tmp/deploy/images/qemu-amd64/
host$ DISTRO_RELEASE=bookworm SWUPDATE_BOOT=y ./start-qemu.sh amd64
```
Copy `update.swu` file from `delta_update_artifacts` folder into the running system:
```
host$ cd scripts/delta_update_artifacts
host$ scp -P 22222 ./update.swu root@localhost:
```
### Delta Software Update Verification

Follow the steps mentioned in the section [SWUpdate verification](#swupdate-verification) for verification.

Since our target was to update the root file system by adding a few packages (vim and nano in this example), Check if the packages are available after the update by running either the `vim` command or `nano` command.

## Delta Software Update using delta handler

Before proceeding, make sure the package `zchunk` is available in the system.

Under Debian/Ubuntu, zchunk can be installed using the following command:  
```
host$ sudo apt-get install zchunk
```

Delta software update with delta handler (zchunk) requires the zck file to be uploaded to a server and the url of the zck file to be included in the `sw-description` file.

For example, Apache server can be used to host the .zck file and make sure the server is accessible to the target (QEMU or HW).

Under Debian/Ubuntu, Apache can be installed using the following command:  
```
host$ sudo apt-get install apache2
```
The files that are served by the Apache server are placed in `/var/www/html`

If Apache server is used, then create a directory named `artifacts` inside `/var/www/html` and copy the .zck file (which will be created in the next step) in the `artifacts` folder.

In the above case, the file url will be `http://<SERVER_IP>/artifacts/update.delta.zck`

For creating a delta update artifact for the delta handler, navigate to the `scripts` folder and run the `create_delta_swu.sh` file with the following commands:
```
host$ cd scripts
host$ sudo ./create_delta_swu.sh --type zchunk --url <url of the zck file> ../image1 ../image2
host$ cd ../
```

The `create_delta_swu.sh` creates a folder named `delta_update_artifacts` in the current directory which has the delta update artifacts. 

Now start the first image (which does not contain the packages vim and nano), run the following commands:
```
host$ sudo rm -r build/tmp/deploy/images/qemu-amd64/*
host$ cp -r ./image1/* build/tmp/deploy/images/qemu-amd64/
host$ DISTRO_RELEASE=bookworm SWUPDATE_BOOT=y ./start-qemu.sh amd64
```
Copy `update.swu` file from `delta_update_artifacts` folder into the running system:
```
host$ cd scripts/delta_update_artifacts
host$ scp -P 22222 ./update.swu root@localhost:
```
**NOTE**: Make sure the .zck file in `delta_update_artifacts` folder is copied to the apache server directory `/var/www/html/artifacts` and is accessible through the server used.

### Delta Software Update Verification

Follow the steps mentioned in the section [Delta Software Update Verification](#delta-software-update-verification) for verification.

# Building and testing the CIP Core image for BBB

Follow the steps mentioned in the section [Building and testing the CIP Core image](README.swupdate.md#building-and-testing-the-cip-core-image) for creating images and .swu files.
- Replace qemu-amd64.yml kas file with BBB board specific file i.e bbb.yml
- .swu file will be generated in the following folder build/tmp/deploy/images/bbb/
- Create Non-RT and RT Kernel images as mentioned in the section

Flash the BeagleBone Black RT kernel image into SDcard
```
host$ dd if=build/tmp/deploy/images/bbb/cip-core-image-cip-core-bullseye-bbb.wic \
   of=/dev/<medium-device> bs=1M status=progress
```

After flashing the BBB RT kernel image into SD card, mount the SD card on host PC and copy .swu file from `tmp` folder to root partition like below.

```
host$ sudo cp tmp/cip-core-image-cip-core-bullseye-bbb.swu /<mnt>/home/root/
```

Connect a serial port cable between host PC and BBB.
Insert SD card to BBB, hold S2 button while applying power supply to BBB.

For verifying swupdate on BBB use the same steps as mentioned in above [SWUpdate Verification](README.swupdate.md#swupdate-verification).
