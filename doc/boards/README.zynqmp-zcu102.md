# ISAR CIP Core: Instructions for the Zynq UltraScale+ MPSoC ZCU102 evaluation board

## Build the CIP Core image

Set up `kas-container` as described in the [top-level README](../../README.md).
Then build the base image,

```
$ ./kas-container menu
```

Select below options to create base image,
and click on Build to start the build.

* Kernel 6.1.x-cip
* Bookworm (12)

After the build is finished, insert a SDCard and flash the image.

## Prepare to boot from QSPI

The board must be prepared to boot from QSPI.

Please refer to the official website of the board below:
- https://www.amd.com/en/products/adaptive-socs-and-fpgas/evaluation-boards/ek-u1-zcu102-g.html

and configure the board.

## U-boot settings

In order to boot from the SDCard, we need to set some environment variable on u-boot.
Switch on the board and the u-boot intaractive command line to set the environment variables.

```
u-boot > setenv cip_serverip '192.168.0.1'
u-boot > setenv cip_tftppath '/tftp'
u-boot > setenv cip_nfspath  '/nfsrootfs'
u-boot > setenv cip_kernel   'Image'
u-boot > setenv cip_fdt_file 'zynqmp-zcu102-rev1.0.dtb'
u-boot > setenv cip_bootargs 'setenv bootargs "console=ttyPS0,115200n8 root=/dev/nfs rw nfsroot=${cip_serverip}:${cip_nfspath},vers=4,tcp,hard ip=dhcp"'
u-boot > setenv cip_bootcmd 'setenv autoload no && setenv initrd_high 0xffffffff && setenv fdt_high 0xffffffff && dhcp && setenv serverip ${cip_serverip} && tftpboot ${kernel_addr_r} ${cip_tftppath}/${cip_kernel} && tftpboot ${fdt_addr_r} ${cip_tftppath}/${cip_fdt_file} && run cip_bootargs && booti ${kernel_addr_r} - ${fdt_addr_r}'
```

you can boot from the Network via TFTP/NFS servers as follows:

```
u-boot > run cip_bootcmd
```
