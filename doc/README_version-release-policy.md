# CIP metadata versioning and Release policy

## Table of contents
1. [Objective](#objective)
2. [Versioning system](#versioningsystem)
3. [Release policy](#releasepolicy)

## Objective <a name="objective"></a>

The primary objective is to document the release process, it’s frequency and version changing for isar-cip-core metadata. This metadata can be used by CIP users to create various flavors of images like **security-hardened image, testing image, partition-encrypted image** etc. in architectures like **x86_64, arm64, armhf, riscv64**.

## Versioning system <a name="versioningsystem"></a>

The isar-cip-core metadata follows semantic versioning system i.e **x.y.z** format which is explained below:

1. **z** is incremented only when critical bugs are fixed. If **z** is zero, it will be left out.
    * For example, if the latest release version is **2.2.5**, then the upcoming release version after fixing some critical bugs will be **2.2.6**.

2. **y** is incremented for each Debian point release or in case of isar-cip-core regular release. When **y** is incremented, **z** is reset to 0.
    * Let us assume that the latest release version is **2.1.1**, then the upcoming regular release version will be **2.2**.

3. **x** is incremented when significant changes are done other than **y** and **z**.
    * In cases where recipes are broken fundamentally, or support for an older Debian version is dropped then the value of x is incremented by 1.
    * Let us assume that the latest release version is **1.0.1**. If changes similar to the one mentioned above are done, then the next release will be **2.0**. When **x** is incremented, **y** and **z** are reset to 0.

## Release policy <a name="releasepolicy"></a>

An approximate time gap of 3 months is taken between consecutive regular releases. During every release, CIP-Core plans to give out recipes (isar-cip-core metadata) using which the user can build the flavor of their choice.

All the releases can be found [here](https://gitlab.com/cip-project/cip-core/isar-cip-core/-/tags).
