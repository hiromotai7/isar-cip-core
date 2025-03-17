# Certificate handling in isar-cip-core

This document describes how to replace the certificates or certificate handlers
in isar-cip-core.

In isar-cip-core provides the infrastructure to sign:
 - efi binaries
   - efibootguard binary
   - unified kernel image
 - update binary for SWUPDATE

isar-cip-core uses the Debian snakeoil keys as to provide an example and during
testing.


## Signing an update binary(*.swu)

An swu contains an signed sw-description file with the name sw-description.sig. This file is
created during the swu image build process by calling a script call `/usr/bin/sign-swu`.
The script is called by class classes/swupdate.bbclass. The script has the following
call signature:

```
sign-swu <unsigned efi binary> <signed efi binary>
```

The default implementation of isar-cip-core is `recipes-devtools/swupdate-signer/swupdate-signer-cms_0.1.bb`.

To validate a signed *.swu the image needs to contain the public part of the certificate which
is stored in the recipe `recipes-devtools/swupdate-certificates/swupdate-certificates_0.2.bb`

## Signing an EFI binary

EFI binaries are signed with the script `/usr/bin/sign_secure_image.sh`.
The script is called by the wic plugins scripts/lib/wic/plugins/source/efibootguard-boot.py
and scripts/lib/wic/plugins/source/efibootguard-efi.py. The script has the following
call signature:
```
sign_secure_image <unsigned efi binary> <signed efi binary>
```

# Replace signing scripts

The preferred way to add your own signer is to use
the overload the necessary recipes with `PREFERRED_PROVIDER`.

## SWUPDATE update binaries (*.swu)

To use a project specific signing script, e.g. when using a HSM,
add the following lines to the build configuration (kas file or in the
conf directory).

```
PREFERRED_PROVIDER_swupdate-signer = "<swu signing package>"
```

The project specific public certifcate can be replaced by
setting:
```
PREFERRED_PROVIDER_swupdate-certificates = "<swu certificate>"
```

### Content of the swu signing package

The efi siging package needs to provide an script at the
location  `/usr/bin/sign-swu` with the call signature:

```
sign-swu <unsigned file name> <signature file name>
```

## efi binaries

To use a project specific own signing script, e.g. when using a HSM,
add the following lines to the build configuration (kas file or in the
conf directory).

```
PREFERRED_PROVIDER_ebg-secure-boot-signer = "<efi signing package>"
```

Alternativly the an own file name can be used by modifing the signwith parameter
of the boot partitions and bootloader partition as described in [README.secureboot.md](./doc/README.secureboot.md#wic)

### Content of the efi signing package

The efi siging package needs to provide an script at the
location  `/usr/bin/sign_secure_image.sh` with the call signature:

```
sign_secure_image <unsigned efi binary> <signed efi binary>
```

