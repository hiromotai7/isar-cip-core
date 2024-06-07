# CIP Core functionality testing with LAVA

This document explains how SWUpdate, Secure boot and IEC layer are being tested using LAVA. The tests/templates directory contains functionality based templates which are extended to LAVA job definitions which tests the respective functionality on QEMU amd64, arm64 and arm architectures. CI jobs run until the final health of all the submitted jobs is reported. Test results are also pushed to [CIP SQUAD platform](https://squad.ciplatform.org/cip-core/).

## Templates

#### IEC_template.yml:
This template is extended to three LAVA job definitions which runs [IEC layer test cases](https://gitlab.com/cip-project/cip-testing/cip-security-tests) on the QEMU security target. Here is a [reference](https://lava.ciplatform.org/scheduler/job/1143475/definition) to the IEC job definition.

#### secureboot_template.yml:
This template is extended to three LAVA job definitions which checks whether secure boot is enabled on the QEMU security target. Here is a [reference](https://lava.ciplatform.org/scheduler/job/1143474/definition) to the secure boot job definition.

#### swupdate_template.yml:
This template is extended to five LAVA job definitions in which three jobs verify successful software update, partition switch after reboot and checking whether bootloader environment variables(ustate) are updated. Here is a [reference](https://lava.ciplatform.org/scheduler/job/1143538/definition) to the software update job definition.

The other two jobs i.e [kernel_panic.yml](https://lava.ciplatform.org/scheduler/job/1143642/definition) and [initramfs_crash.yml](https://lava.ciplatform.org/scheduler/job/1143643/definition) verify the roll back feature during a fail case scenarios.

## LAVA Setup

The above mentioned job definitions shall be sent to CIP LAVA Lab for testing. For local testing please follow the steps mentioned in [CIP LAVA Docker](https://gitlab.com/cip-project/cip-testing/lava-docker/-/tree/cip-lava-docker?ref_type=heads#linaros-automated-validation-architecture-lava-docker-container) to have your own setup.

## LAVA template variables

* `architecture` : This variable represents architecture of the QEMU security target on which the test is done.
* `project_url` : Default value is `https://s3.eu-central-1.amazonaws.com/download2.cip-project.org/cip-core`.
* `branch` : This variable represents the branch on which the pipeline is triggered.
* `distribution` : This variable is assigned with the `release` assigned in gitlab CI configuration file.
* `Firmware_args` : This variable is used only for `arm64` and `armhf` architectures and it has boot parameters for the U-boot firmware binary.
* `Firmware_url` : This variable represents the firmware binary artifact uploaded in cip-project s3 bucket.
