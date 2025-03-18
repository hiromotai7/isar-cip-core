# Handling of signing processes in isar-cip-core

This document describes how to replace the signing scripts
in isar-cip-core.

In isar-cip-core provides the infrastructure to sign:
 - EFI binaries
   - efibootguard binary
   - unified kernel image
 - update binary for SWUpdate

isar-cip-core uses the Debian snake-oil keys as to provide an example and during
testing.


## Signing an update binary(*.swu)

A swu contains the signature of the `sw-description` file with the name `sw-description.sig`.
This `sw-description.sig` file is created during the swu image build process by calling
a script call `/usr/bin/sign-swu`. The script is called by class classes/swupdate.bbclass.
The script has the following call signature:

`sign-swu <unsigned file name> <signature file name>`

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

The default implementation of isar-cip-core is `recipes-devtools/ebg-secure-boot-signer/ebg-secure-boot-signer_0.2.bb`.
The certificates used by that script are provided by the package
`recipes-devtools/secure-boot-secrets/secure-boot-snakeoil_0.2.bb`.

# Replace signing scripts

The preferred way to add your own signer is to use
the overload the necessary recipes with `PREFERRED_PROVIDER`.

## SWUpdate update binaries (*.swu)

To use a project specific signing script, e.g. when using a HSM,
add the following lines to the build configuration (kas file or in the
conf directory).

`PREFERRED_PROVIDER_swupdate-signer = "<swu signing package>"`

The project specific public certificate can be replaced by
setting:
`PREFERRED_PROVIDER_swupdate-certificates = "<swu certificate>"`

### Content of the swu signing package

The swu signing package needs to provide an script at the
location `/usr/bin/sign-swu` with the call signature:

`sign-swu <unsigned file name> <signature file name>`

The package can provide additional files necessary for the signing process
or a separate package can be used.

## EFI binaries

To use a project specific own signing script, e.g. by using an HSM,
add the following lines to the build configuration (kas file or in the
`conf` directory).

`PREFERRED_PROVIDER_ebg-secure-boot-signer = "<efi signing package>"`

Alternatively an own file name can be used by modifying the signwith parameter
of the boot partitions and bootloader partition as described in [README.secureboot.md](./doc/README.secureboot.md#wic)

### Content of the efi signing package

The efi signing package needs to provide an script at the
location `/usr/bin/sign_secure_image.sh` with the call signature:

`sign_secure_image <unsigned efi binary> <signed efi binary>`

The package can provide additional files necessary for the signing process
or a separate package can be used.
