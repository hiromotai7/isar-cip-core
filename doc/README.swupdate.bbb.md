# SWUpdate support for the CIP core image

This document describes how to build and test the SWUpdate on BBB

Start with cloning the isar-cip-core repository:
```
host$ git clone https://gitlab.com/cip-project/cip-core/isar-cip-core.git
host$ cd isar-cip-core
```

# Building and testing the CIP Core image

Set up `kas-container` as described in the [top-level README](../README.md).
Then build the image which will later serve as update package:
```
host$ ./kas-container build kas-cip.yml:kas/board/bbb.yml:kas/opt/swupdate.yml
```

To flash, e.g., the BeagleBone Black image to an SD card, run
```
dd if=build/tmp/deploy/images/bbb/cip-core-image-cip-core-bullseye-bbb.wic \
        of=/dev/<medium-device> bs=1M status=progress
```

or via bmap-tools
```
bmaptool copy build/tmp/deploy/images/bbb/cip-core-image-cip-core-bullseye-bbb.wic /dev/<medium-device>
```

Prepare the hardware connections

* Connect a serial port cable between the host PC and the BBB
* Connect an Ethernet cable between the host PC and the BBB

Insert SD card to BBB, hold S2 button while applying power suppy to BBB.

Once the system is up, check which partition is booted, e.g. with "df -h" command :
```
root@demo:~# df -h
Filesystem      Size  Used Avail Use% Mounted on
udev            238M     0  238M   0% /dev
tmpfs           500M  6.5M  494M   2% /run
/dev/mmcblk0p2  2.5G  297M  2.1G  13% /
tmpfs           249M     0  249M   0% /dev/shm
tmpfs           5.0M     0  5.0M   0% /run/lock
tmpfs           249M     0  249M   0% /sys/fs/cgroup
tmpfs           249M     0  249M   0% /tmp
/dev/mmcblk0p1   32M  936K   32M   3% /boot
```

In host PC, configure below settings for Ethernet IPv4. 

* IP address: 192.168.2.1
* Subnet mask: 255.255.255.0

Execute below command to confirm 192.168.2.1 is accessible from BBB.
```
root@demo:~# ping 192.168.2.1
```

Copy .swu file to BBB from host PC using below command.
```
host$ scp build/tmp/deploy/images/bbb/cip-core-image-cip-core-bullseye-bbb.swu root@192.168.2.2:/root/
```

Now apply swupdate and reboot
```
root@demo:~# swupdate -i cip-core-image-cip-core-bullseye-bbb.swu
root@demo:~# reboot
```

Check which partition is booted, e.g. with "df -h" command and the rootfs should have changed
```
root@demo:~# df -h
Filesystem      Size  Used Avail Use% Mounted on
udev            238M     0  238M   0% /dev
tmpfs           500M  6.5M  494M   2% /run
/dev/mmcblk0p3  2.5G  297M  2.1G  13% /
tmpfs           249M     0  249M   0% /dev/shm
tmpfs           5.0M     0  5.0M   0% /run/lock
tmpfs           249M     0  249M   0% /sys/fs/cgroup
tmpfs           249M     0  249M   0% /tmp
/dev/mmcblk0p1   32M  936K   32M   3% /boot
```

Set ustate to 0 after successful swupdate
```
root@demo:~# ln -s /usr/bin/fw_printenv /usr/bin/fw_setenv
root@demo:~# fw_setenv ustate 0
```
