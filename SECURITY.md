How to customize images for security features
=============================================

This is the "temporal" document about how to create and use
the CIP Core generic profile images for security feature evaluation.

Official manuals
----------------

* isar-cip-core: https://gitlab.com/zuka0828/isar-cip-core/-/blob/master/README.md
* ISAR User Manual: https://github.com/ilbers/isar/blob/master/doc/user_manual.md

Assumed environment
-------------------

* isar-cip-core: master branch
* Host: Debian 10 buster amd64
    * Installed packages: `docker-ce`, `qemu-system`
    * Users who does the following actions must be in the groups `docker` and `kvm`

Create image recipe
-------------------

Create the recipe `recipes-core/images/cip-core-image-security.bb`
to generate a image including required packages.
We can install existing Debian packages by setting
`IMAGE_PREINSTALL` in the image recipe.

Example:

    IMAGE_PREINSTALL = "openssl"

Build images
------------

Build images for QEMU x86 64bit machine.

    $ ./kas-docker --isar build --target cip-core-image-security kas.yml:board-qemu-amd64.yml

Run on QEMU
-----------

Run the generated images on QEMU (x86 64bit).

    $ ./start-qemu.sh amd64
