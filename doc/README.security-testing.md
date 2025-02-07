# CIP security testing
This document explains how to verify basic implementations of [CIP security requirements](https://gitlab.com/cip-project/cip-documents/-/blob/master/security/security_requirements.md) in the isar-cip-core security image using [cip-security-tests](https://gitlab.com/cip-project/cip-testing/cip-security-tests).

# Pre-requisites
- Necessary debian packages to implement CIP security requirements, include them in the recipe [cip-core-image-security.bb](recipes-core/images/cip-core-image-security.bb)

- Pre configurations in the image, should be added in the `postinst` script of security-customizations [security-customizations/files/postinst](recipes-core/security-customizations/files/postinst)

# Build CIP security Linux image
Clone isar-cip-core repository
```
host$ git clone https://gitlab.com/cip-project/cip-core/isar-cip-core.git
host$ cd isar-cip-core
```
Build Security Linux image by selecting necessary options. The board, Kernel version and Debian release options chosen below are shown as an example.
```
host$ ./kas-container menu
    Select QEMU AMD64 (x86-64) as Target Board
    Select Kernel 5.10.x-cip as CIP Kernel version
    Select bullseye (11) as Debian Release
    Select Security extensions Option under Image features
Save & Build
```
# Boot the Linux image
```
host$ ./start-qemu.sh x86
```

# Copy security tests in to the Linux image
- Clone the cip-security-tests from following URL
```
host$ git clone https://gitlab.com/cip-project/cip-testing/cip-security-tests
```
- Add test user in Linux image to scp and run the `cip-security-tests`
```
image$ adduser test
```
- Copy `cip-security-tests` to Linux image using scp command
```
host$ scp -r -P 22222 cip-security-tests/ test@127.0.0.1:/home/test/
```

# Run the tests in Linux image
- Go to following directory and execute IEC Layer test
```
image$ cd /home/test/cip-security-tests/iec-security-tests/singlenode-testcases/
image$ ./run_all.sh
```
`run_all.sh` generates the test result in file `result_file.txt`, and the output looks like below.
```
TC_CR1.1-RE1_1+pass+11
TC_CR1.11_1+pass+22
TC_CR1.11_2+pass+30
TC_CR1.1_1+pass+5
TC_CR1.1_2+pass+6
TC_CR1.3_1+pass+7
TC_CR1.3_2+pass+4
TC_CR1.3_3+pass+5
TC_CR1.4_1+pass+7
TC_CR1.5_2+pass+13
TC_CR1.5_3+pass+10
TC_CR1.7-RE1_1+pass+5
 :
 .
[Truncated]
```
Each line of the output will have this \<requirement number\>+<requirement pass/fail>+\<time took to execute this test case\>
- pass - The security image is meeting this requirement.
- fail - The security image is failed to met this requirement.
- skip - The test case not supported by IEC layer.
