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

Create kas file
---------------

Create a kas file named `opt-security.yml` to add security settings.

Add security packages to rootfs
-------------------------------

Set `IMAGE_PREINSTALL` to the list of packages required to enable
the security features. This variable can be set through the kas file.

Example:

```
local_conf_header:
  security: |
    IMAGE_PREINSTALL = "openssl"
```

Build images
------------

Build images for QEMU x86 64bit machine:

    $ ./kas-docker --isar build kas.yml:board-qemu-amd64.yml:opt-security.yml

Run on QEMU
-----------

Run the generated images on QEMU (x86 64bit).

    $ ./start-qemu.sh amd64
