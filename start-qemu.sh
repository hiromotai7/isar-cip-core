#!/bin/sh
#
# CIP Core, generic profile
#
# Copyright (c) Siemens AG, 2019-2024
#
# Authors:
#  Jan Kiszka <jan.kiszka@siemens.com>
#
# SPDX-License-Identifier: MIT
#

usage()
{
	echo "Usage: $0 [ARCHITECTURE [QEMU_OPTIONS]]"
	echo
	echo "The architecture defaults to the setting in .config.yaml and can be left out"
	echo "if the built was done via \"kas-container menu\"."
	echo
	echo "Environment variables (default to settings in .config.yaml):"
	echo "  QEMU_PATH         use a locally built QEMU version"
	echo "  SWUPDATE_BOOT     boot swupdate image"
	echo "  SECURE_BOOT       start a secure boot environment"
	echo "  DISTRO_RELEASE    select a specific Debian release"
	echo "  TARGET_IMAGE      select a specific image type"
	exit 1
}

if grep -s -q "IMAGE_SECURE_BOOT: true" .config.yaml; then
	SECURE_BOOT="true"
elif grep -s -q "IMAGE_SWUPDATE: true" .config.yaml; then
	SWUPDATE_BOOT="true"
fi
if grep -s -q "IMAGE_DATA_ENCRYPTION: true" .config.yaml; then
	TPM2_ENCRYPTION="true"
fi

if [ -n "${QEMU_PATH}" ]; then
	QEMU_PATH="${QEMU_PATH}/"
fi

if [ -z "${DISTRO_RELEASE}" ]; then
	if grep -s -q "DEBIAN_SID: true" .config.yaml; then
		DISTRO_RELEASE="sid"
	elif grep -s -q "DEBIAN_BUSTER: true" .config.yaml; then
		DISTRO_RELEASE="buster"
	elif grep -s -q "DEBIAN_BOOKWORM: true" .config.yaml; then
		DISTRO_RELEASE="bookworm"
	else
		DISTRO_RELEASE="bullseye"
	fi
fi

if [ -z "${TARGET_IMAGE}" ];then
	TARGET_IMAGE="cip-core-image"
	if grep -s -q "IMAGE_SECURITY: true" .config.yaml; then
		TARGET_IMAGE="cip-core-image-security"
	fi
fi

if grep -s -q "IMAGE_TESTING: true" .config.yaml; then
	TEST_IMAGE="-test"
fi

if [ -n "$1" ]; then
	arch="$1"
	shift 1
else
	if grep -s -q "TARGET_QEMU_AMD64: true" .config.yaml; then
		arch=amd64
	elif grep -s -q "TARGET_QEMU_ARM64: true" .config.yaml; then
		arch=arm64
	elif grep -s -q "TARGET_QEMU_ARM: true" .config.yaml; then
		arch=arm
	elif grep -s -q "TARGET_QEMU_RISCV64: true" .config.yaml; then
		arch=riscv64
	fi
fi

case "${arch}" in
	x86|x86_64|amd64)
		QEMU_ARCH=amd64
		QEMU=qemu-system-x86_64
		QEMU_EXTRA_ARGS=" \
			-cpu qemu64 \
			-smp 4 \
			-machine q35,accel=kvm:tcg \
			-global ICH9-LPC.noreboot=off \
			-device virtio-net-pci,netdev=net"
		if [ -n "${SECURE_BOOT}" ]; then
			# set bootindex=0 to boot disk instead of EFI-shell
			QEMU_EXTRA_ARGS=" \
			${QEMU_EXTRA_ARGS} -device ide-hd,drive=disk,bootindex=0"
		else
			QEMU_EXTRA_ARGS=" \
			${QEMU_EXTRA_ARGS} -device ide-hd,drive=disk"
		fi
		KERNEL_CMDLINE=" \
			root=/dev/sda rw"
		;;
	arm64|aarch64)
		QEMU_ARCH=arm64
		QEMU=qemu-system-aarch64
		QEMU_EXTRA_ARGS=" \
			-cpu cortex-a57 \
			-smp 4 \
			-machine virt \
			-device virtio-serial-device \
			-device virtconsole,chardev=con -chardev vc,id=con \
			-device virtio-blk-device,drive=disk \
			-device virtio-net-device,netdev=net"
		KERNEL_CMDLINE=" \
			root=/dev/vda rw"
		;;
	arm|armhf)
		QEMU_ARCH=arm
		QEMU=qemu-system-arm
		QEMU_EXTRA_ARGS=" \
			-cpu cortex-a15 \
			-smp 2 \
			-machine virt \
			-device virtio-serial-device \
			-device virtconsole,chardev=con -chardev vc,id=con \
			-device virtio-blk-device,drive=disk \
			-device virtio-net-device,netdev=net"
		KERNEL_CMDLINE=" \
			root=/dev/vda rw"
		;;
	rv64|riscv64)
		QEMU_ARCH=riscv64
		QEMU=qemu-system-riscv64
		QEMU_EXTRA_ARGS=" \
			-cpu rv64 \
			-smp 4 \
			-machine virt \
			-device virtio-serial-device \
			-device virtconsole,chardev=con -chardev vc,id=con \
			-device virtio-blk-device,drive=disk \
			-device virtio-net-device,netdev=net"
		KERNEL_CMDLINE=" \
			console=hvc1 console=ttyS0 root=/dev/vda rw"
		;;
	""|--help)
		usage
		;;
	*)
		echo "Unsupported architecture: ${arch}"
		exit 1
		;;
esac

BASE_DIR=$(readlink -f $(dirname $0))
IMAGE_PREFIX="${BASE_DIR}/build/tmp/deploy/images/qemu-${QEMU_ARCH}/${TARGET_IMAGE}-cip-core-${DISTRO_RELEASE}-qemu-${QEMU_ARCH}${TEST_IMAGE}"

if [ -z "${DISPLAY}" ]; then
	QEMU_EXTRA_ARGS="${QEMU_EXTRA_ARGS} -nographic"
	case "${arch}" in
		x86|x86_64|amd64)
			KERNEL_CMDLINE="${KERNEL_CMDLINE} console=ttyS0"
			;;
	esac
fi

QEMU_COMMON_OPTIONS=" \
	-m 1G \
	-serial mon:stdio \
	-netdev user,id=net,hostfwd=tcp:127.0.0.1:22222-:22 \
	${QEMU_EXTRA_ARGS} \
	"

if [ "$TPM2_ENCRYPTION" = "true" ] && [ -x /usr/bin/swtpm ]; then
	SWTPM_DIR="${IMAGE_PREFIX}.swtpm"
	mkdir -p "${SWTPM_DIR}"
	if swtpm socket -d --tpmstate dir="${SWTPM_DIR}" \
			 --ctrl type=unixio,path=/tmp/qemu-swtpm.sock \
			 --tpm2; then
		TPM_DEVICE=tpm-tis-device
		case "${arch}" in
			x86|x86_64|amd64)
				TPM_DEVICE=tpm-tis
				;;
		esac
		QEMU_EXTRA_ARGS="${QEMU_EXTRA_ARGS} \
			 -chardev socket,id=chrtpm,path=/tmp/qemu-swtpm.sock \
			 -tpmdev emulator,id=tpm0,chardev=chrtpm \
			 -device ${TPM_DEVICE},tpmdev=tpm0"
	fi
fi

if [ -n "${SECURE_BOOT}${SWUPDATE_BOOT}" ]; then
	case "${arch}" in
		x86|x86_64|amd64)
			if [ -n "${SECURE_BOOT}" ]; then
				ovmf_code=${OVMF_CODE:-./build/tmp/deploy/images/qemu-amd64/OVMF/OVMF_CODE_4M.secboot.fd}
				ovmf_vars=${OVMF_VARS:-./build/tmp/deploy/images/qemu-amd64/OVMF/OVMF_VARS_4M.snakeoil.fd}

				${QEMU_PATH}${QEMU} \
					-global ICH9-LPC.disable_s3=1 \
					-global isa-fdc.driveA= \
					-drive if=pflash,format=raw,unit=0,readonly=on,file=${ovmf_code} \
					-drive if=pflash,format=raw,file=${ovmf_vars} \
					-drive file=${IMAGE_PREFIX}.wic,discard=unmap,if=none,id=disk,format=raw \
					${QEMU_COMMON_OPTIONS} "$@"
			else
				ovmf_code=${OVMF_CODE:-./build/tmp/deploy/images/qemu-amd64/OVMF/OVMF_CODE_4M.fd}

				${QEMU_PATH}${QEMU} \
					-drive file=${IMAGE_PREFIX}.wic,discard=unmap,if=none,id=disk,format=raw \
					-drive if=pflash,format=raw,unit=0,readonly=on,file=${ovmf_code} \
					${QEMU_COMMON_OPTIONS} "$@"
			fi
			;;
		arm64|aarch64|arm|armhf)
			u_boot_bin=${FIRMWARE_BIN:-./build/tmp/deploy/images/qemu-${QEMU_ARCH}/firmware.bin}

			${QEMU_PATH}${QEMU} \
				-drive file=${IMAGE_PREFIX}.wic,discard=unmap,if=none,id=disk,format=raw \
				-bios ${u_boot_bin} \
				${QEMU_COMMON_OPTIONS} "$@"
			;;
		rv64|riscv64)
			opensbi_bin=${FIRMWARE_BIN:-./build/tmp/deploy/images/qemu-${QEMU_ARCH}/fw_payload.bin}

			${QEMU_PATH}${QEMU} \
				-drive file=${IMAGE_PREFIX}.wic,discard=unmap,if=none,id=disk,format=raw \
				-bios ${opensbi_bin} \
				${QEMU_COMMON_OPTIONS} "$@"
			;;
		*)
			echo "Unsupported architecture: ${arch}"
			exit 1
			;;
	esac
else
		IMAGE_FILE=$(ls ${IMAGE_PREFIX}.ext4)

		KERNEL_FILE=$(ls ${IMAGE_PREFIX}-vmlinu* | tail -1)
		INITRD_FILE=$(ls ${IMAGE_PREFIX}-initrd.img* | tail -1)

		${QEMU_PATH}${QEMU} \
			-drive file=${IMAGE_FILE},discard=unmap,if=none,id=disk,format=raw \
			-kernel ${KERNEL_FILE} -append "${KERNEL_CMDLINE}" \
			-initrd ${INITRD_FILE} \
			${QEMU_COMMON_OPTIONS} "$@"
fi
