# ISAR CIP Core: Instructions for M-COM RT X86 V1

## Build the CIP Core image

Set up `kas-container` as described in the [top-level README](../../README.md).
Then build the base image,
```
host$ ./kas-container menu
```
Select below options to create base image,

* Generic x86 machine booting via UEFI
* Kernel 6.1.x-cip
* Bookworm (12)
* Click on Build to start the build

For SWUpdate image, Just select below additional options on top of base image,

* SWUpdate support for root partition
* Set EFI Boot Guard watchdog timeout in seconds to "0"

For Secure Boot image, Just select below option on top of SWUpdate image options

* Secure boot support

After the build is finished, insert a USB stick and flash the image.

## Software Update and verification

Refer the section [Build the cip core image](README.m-com-x86.md#build-the-cip-core-image) to create the image with Software update enabled,

Copy the .swu file generated from the first build to temporary folder, which will be used for swupdate.

Create second image(RT Kernel image) so, additionally select RT Kernel option on top of SWUpdate image here.

Flash the image with RT Kernel to USB and boot the image from USB. Copy the .swu file from the temporary folder to M-COM device.

For verification, please follow the [SWUpdate verification steps](../README.swupdate.md#swupdate-verification)

## Secure Boot Configuration and Verification

**Note:**
* All the steps are specific to M-COM RT X86 V1 device hence consult device specific manual for other devices for Secure Boot verification.

Copy KeyTool.efi and UEFI keys into USB stick as mentioned in [Secure boot key enrollment](../README.secureboot.md#secure-boot-key-enrollment)

Insert USB memory stick to M-COM device.

Power on and Press F12 key to Enter BIOS setup.

**Note:**
* if you want to restore the default BIOS settings then
Under "Save & Exit" tab, Click on "Restore User Defaults" and select "Yes" to restore default values.

Enable Secure Boot and enter to Setup Mode by following below steps

**Note:**
* Due to following step, old keys will be deleted hence it’s recommended to take backup of old keys to avoid any data loss.

Under Security tab,
* Enable Secure Boot if disabled. The System Mode will be "User" by default.
* Click on "Reset To Setup Mode" to remove existing keys.
   Select "Yes" to delete all Secure Boot keys database
* The System Mode should change to "Setup" once we delete all Secure Boot keys.

Under Save & Exit tab,
* Go to "Boot Override" and click on "UEFI: Built-in EFI shell" which will launch the EFI shell.
* In the EFI shell, run KeyTool.efi from the USB stick and add all Secure Boot keys from USB. Follow the step-4 from the section [Add Keys to OVMF](../README.secureboot.md#add-keys-to-ovmf) to inject the Secure Boot keys.

Exit from the KeyTool.efi and built-in EFI shell to BIOS.

Optionally you can confirm the injected keys like below:

Under security tab,
* Click on "Secure Boot" and then "Key Management" to confirm the injected Secure Boot keys (DB, KEK and PK).

Under Save & Exit" tab
* Click on "Save Changes & Exit".

Now the keys are injected, remove the USB stick.

Refer the section [Build the cip core image](README.m-com-x86.md#build-the-cip-core-image) to create secure boot enabled image,

Once build is completed, flash the Secure Boot image to USB stick and insert the USB memory stick to M-COM device.

Power on and Press F12 key to Enter BIOS setup.

In the BIOS, Configure the device to boot from USB by following below steps

Under "Boot" tab,

* Select "Boot Option #1" as USB device from the "Boot Option Priorities" section.

Under "Save & Exit" tab,

* Click on "Save Changes & Exit". The M-COM board starts to boot the image from USB.

After boot, check the dmesg for Secure Boot status like below:
```
root@demo:~# dmesg | grep Secure
[    0.008368] Secure boot enabled
```
