#!/bin/bash
# Copyright (C) 2024, Renesas Electronics Europe GmbH
# Chris Paterson <chris.paterson2@renesas.com>
# Sai Ashrith <sai.sathujoda@toshiba-tsip.com>
################################################################################

set -e

################################################################################
LAVA_TEMPLATES="tests/templates"
LAVA_JOBS_URL="https://${CIP_LAVA_LAB_SERVER:-lava.ciplatform.org}/scheduler/job"
LAVA_API_URL="https://${CIP_LAVA_LAB_SERVER:-lava.ciplatform.org}/api/v0.2"
LAVACLI_ARGS="--uri https://$CIP_LAVA_LAB_USER:$CIP_LAVA_LAB_TOKEN@${CIP_LAVA_LAB_SERVER:-lava.ciplatform.org}/RPC2"
SQUAD_GROUP="cip-core"
SQUAD_WATCH_JOBS_URL="${CIP_SQUAD_URL}/api/watchjob"
SQUAD_LAVA_BACKEND="${CIP_SQUAD_LAVA_BACKEND:-cip}"
PROJECT_URL="https://s3.eu-central-1.amazonaws.com/download2.cip-project.org/cip-core"

WORK_DIR=$(pwd)
RESULTS_DIR="$WORK_DIR/results"
ERROR=false
TEST=$1
COMMIT_REF=$2
RELEASE=$3
COMMIT_BRANCH=$4

if [ -z "$SUBMIT_ONLY" ]; then SUBMIT_ONLY=false; fi

# Create a dictionary to handle image arguments based on architecture
declare -A image_args
image_args[amd64]="-cpu qemu64 -machine q35,accel=tcg  -global ICH9-LPC.noreboot=off -device ide-hd,drive=disk -drive if=pflash,format=raw,unit=0,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.secboot.fd -device virtio-net-pci,netdev=net -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_VARS_4M.snakeoil.fd  -global ICH9-LPC.disable_s3=1 -global isa-fdc.driveA= -device tpm-tis,tpmdev=tpm0"
image_args[arm64]="-cpu cortex-a57 -machine virt -device virtio-serial-device -device virtconsole,chardev=con -chardev vc,id=con -device virtio-blk-device,drive=disk -device virtio-net-device,netdev=net -device tpm-tis-device,tpmdev=tpm0"
image_args[arm]="-cpu cortex-a15 -machine virt -device virtio-serial-device -device virtconsole,chardev=con -chardev vc,id=con -device virtio-blk-device,drive=disk -device virtio-net-device,netdev=net -device tpm-tis-device,tpmdev=tpm0"

set_up (){
	echo "Installing dependencies to run this script..."
	sudo apt update && sudo apt install -y --no-install-recommends lavacli curl
	job_dir="$(mktemp -d)"
}

clean_up () {
	rm -rf "$job_dir"
}

# This method is called only for arm64 and arm targets while building job definitions
add_firmware_artifacts () {
	sed -i "s@#Firmware#@firmware:@g" "$2"
	sed -i "s@#Firmware_args#@image_arg: '-bios {firmware}'@g" "$2"
	sed -i "s@#Firmware_url#@url: ${PROJECT_URL}/${COMMIT_BRANCH}/qemu-${1}/firmware.bin@g" "$2"
}

# This method creates LAVA job definitions for QEMU amd64, arm64 and armhf
# The created job definitions test SWUpdate, Secureboot and IEC layer
create_jobs () {
	if [ "$1" = "IEC_Layer_test" ]; then
		for arch in amd64 arm64 arm
		do
			cp $LAVA_TEMPLATES/IEC_template.yml "${job_dir}"/IEC_${arch}.yml

			if [ $arch != amd64 ]; then
				add_firmware_artifacts $arch "${job_dir}"/IEC_${arch}.yml
			fi
		done

	elif [ "$1" = "software_update_test" ]; then
		if [ -z "$2" ]; then
			for arch in amd64 arm64 arm
			do
				cp $LAVA_TEMPLATES/swupdate_template.yml "${job_dir}"/swupdate_${arch}.yml

				if [ $arch != amd64 ]; then
					add_firmware_artifacts $arch "${job_dir}"/swupdate_${arch}.yml
				fi
			done
		else
			cp $LAVA_TEMPLATES/swupdate_template.yml "${job_dir}"/"${2}"_amd64.yml
			sed -i "s@software update testing@${2}@g" "${job_dir}"/"${2}"_amd64.yml
			sed -i "s@) = 2@) = 0@g" "${job_dir}"/"${2}"_amd64.yml
			if [ "$2" = "kernel_panic" ]; then
				sed -i "s@kernel: C:BOOT1:linux.efi@Kernel panic - not syncing: sysrq triggered crash@g" "${job_dir}"/"${2}"_amd64.yml
			else
				sed -i "s@kernel: C:BOOT1:linux.efi@Can't open verity rootfs - continuing will lead to a broken trust chain!@g" "${job_dir}"/"${2}"_amd64.yml
				sed -i "s@echo software update is successful!!@dd if=/dev/urandom of=/dev/sda5 bs=512 count=1@g" "${job_dir}"/"${2}"_amd64.yml
			fi
		fi
	else
		for arch in amd64 arm64 arm
		do
			cp $LAVA_TEMPLATES/secureboot_template.yml "${job_dir}"/secureboot_${arch}.yml

			if [ $arch != amd64 ]; then
				add_firmware_artifacts $arch "${job_dir}"/secureboot_${arch}.yml
			fi
		done
	fi

	if [ "$2" = "kernel_panic" ]; then
		sed -i "s@#branch#@maintain-lava-artifact@g" "${job_dir}"/"${2}"_amd64.yml
	elif [ "$2" = "kernel_panic" ]; then
		sed -i "s@#branch#@${COMMIT_BRANCH}@g" "${job_dir}"/"${2}"_amd64.yml
	else
		sed -i "s@#branch#@${COMMIT_BRANCH}@g" "${job_dir}"/*.yml
	fi
	sed -i "s@#distribution#@${release}@g" "${job_dir}"/*.yml
	sed -i "s@#project_url#@${PROJECT_URL}@g" "${job_dir}"/*.yml

	for arch in amd64 arm64 arm
	do
		sed -i "s@#architecture#@${arch}@g" "${job_dir}"/*${arch}.yml
		sed -i "s@#imageargs#@${image_args[$arch]}@g" "${job_dir}"/*${arch}.yml
	done
}

create_cip_core_jobs () {
	if [ "$TEST" = "IEC" ]; then
		create_jobs IEC_Layer_test
	elif [ "$TEST" = "swupdate" ]; then
		create_jobs software_update_test
		create_jobs software_update_test kernel_panic
		create_jobs software_update_test initramfs_crash
	else
		create_jobs secure_boot_test
	fi
}

# This method attaches SQUAD watch job to the submitted LAVA job
# $1: LAVA Job ID
submit_squad_watch_job(){
# SQUAD watch job submission
	local ret
	if [ -z ${CIP_SQUAD_LAB_TOKEN+x} ]; then
		echo "SQUAD_LAB_TOKEN not found, omitting SQUAD results reporting!"
		return 0
	fi

	if [ "$TEST" = "swupdate" ]; then
		squad_project="swupdate-testing"
	elif [ "$TEST" = "secure-boot" ]; then
		squad_project="secure-boot-testing"
	else
		squad_project="iec-layer-testing"
	fi

	local DEVICE=$2
	local ENV="${DEVICE}_${squad_project}"
	local squad_url="$SQUAD_WATCH_JOBS_URL/${SQUAD_GROUP}/${squad_project}/${COMMIT_REF}/${ENV}"
	ret=$(curl -s \
		--header "Authorization: token $CIP_SQUAD_LAB_TOKEN" \
		--form backend="$SQUAD_LAVA_BACKEND" \
		--form testjob_id="$1" \
		--form metadata='{"device": "'${DEVICE}'", "CI pipeline": "'${CI_PIPELINE_URL}'", "CI job": "'${CI_JOB_URL}'"}' \
		"$squad_url")

	if [[ $ret != [0-9]* ]]
	then
		echo "Something went wrong with SQUAD watch job submission. SQUAD returned:"
		echo "${ret}"
		echo "SQUAD URL: ${squad_url}"
		echo "SQUAD Backend: ${SQUAD_LAVA_BACKEND}"
		echo "LAVA Job Id: $1"
	else
		echo "SQUAD watch job submitted successfully as #${ret}."
	fi
}

# $1: Job definition file
submit_job() {
        # Make sure yaml file exists
	if [ -f "$1" ]; then
		echo "Submitting $1 to LAVA master..."
		# Catch error that occurs if invalid yaml file is submitted
		local ret=$(lavacli $LAVACLI_ARGS jobs submit "$1") || error=true

		if [[ $ret != [0-9]* ]]
		then
			echo "Something went wrong with job submission. LAVA returned:"
			echo "${ret}"
		else
			echo "Job submitted successfully as #${ret}."

			local lavacli_output=${job_dir}/lavacli_output
			lavacli $LAVACLI_ARGS jobs show "${ret}" \
				> "$lavacli_output"

			local status=$(cat "$lavacli_output" \
				| grep "state" \
				| cut -d ":" -f 2 \
				| awk '{$1=$1};1')
			STATUS[${ret}]=$status

			local health=$(cat "$lavacli_output" \
				| grep "Health" \
				| cut -d ":" -f 2 \
				| awk '{$1=$1};1')
			HEALTH[${ret}]=$health

			local device_type=$(cat "$lavacli_output" \
				| grep "device-type" \
				| cut -d ":" -f 2 \
				| awk '{$1=$1};1')
			DEVICE_TYPE[${ret}]=$device_type

			local device=$(cat "$lavacli_output" \
				| grep "device      :" \
				| cut -d ":" -f 2 \
				| awk '{$1=$1};1')
			DEVICE[${ret}]=$device

			local test=$(cat "$lavacli_output" \
				| grep "description" \
				| rev | cut -d "_" -f 1 | rev)
			TEST[${ret}]=$test

			submit_squad_watch_job "${ret}" "${device}"

			JOBS+=("${ret}")

		fi
	fi
}

# $1: Device-type to search for
is_device_online () {
	local lavacli_output=${job_dir}/lavacli_output

	# Get list of all devices
	lavacli $LAVACLI_ARGS devices list > "$lavacli_output"

	# Count the number of online devices
	local count=$(grep "(${1})" "$lavacli_output" | grep -c "Good")
	echo "There are currently $count \"${1}\" devices online."

	if [ "$count" -gt 0 ]; then
		return 0
	fi
	return 1
}

submit_jobs () {
	local ret=0
	for JOB in "${job_dir}"/*.yml; do
		local device=$(grep device_type "$JOB" | cut -d ":" -f 2 | awk '{$1=$1};1')
		if is_device_online "$device"; then
			submit_job "$JOB"
		else
			echo "Refusing to submit test job as there are no suitable devices available."
			ret=1
		fi
	done
	return $ret
}

# This method is added with the intention to check if all the jobs are valid before submit
# If even a single definition is found to be invalid, then no job shall be submitted until
# it is fixed by the maintainer
validate_jobs () {
	local ret=0
	for JOB in "${job_dir}"/*.yml; do
		if lavacli $LAVACLI_ARGS jobs validate "$JOB"; then
			echo "$JOB is a valid definition"
		else
			echo "$JOB is not a valid definition"
			ret=1
		fi
	done
	return $ret
}

check_if_all_finished () {
	for i in "${JOBS[@]}"; do
		if [ "${STATUS[$i]}" != "Finished" ]; then
			return 1
		fi
	done
	return 0
}

check_for_test_error () {
	for i in "${JOBS[@]}"; do
		if [ "${HEALTH[$i]}" != "Complete" ]; then
			return 0
		fi
	done
	return 1
}

# $1: LAVA job ID to show results for
get_test_result () {
	if [ -n "${1}" ]; then
		lavacli "$LAVACLI_ARGS" results "${1}"
	fi
}

get_junit_test_results () {
	mkdir -p "${RESULTS_DIR}"
	for i in "${JOBS[@]}"; do
		curl -s -o "${RESULTS_DIR}"/results_"$i".xml "${LAVA_API_URL}"/jobs/"$i"/junit/
	done
}

# $1: Test to print before job summaries
# $2: Set to true to print results for each job
print_status () {
	if [ -z "${1}" ]; then
	# Set default text
		local message="Current job status:"
	else
		local message="${1}"
	fi

	echo "------------------------------"
	echo "${message}"
	echo "------------------------------"
	for i in "${JOBS[@]}"; do
		echo "Job #$i: ${STATUS[$i]}"
		echo "Health: ${HEALTH[$i]}"
		echo "Device Type: ${DEVICE_TYPE[$i]}"
		echo "Device: ${DEVICE[$i]}"
		echo "Test: ${TEST[$i]}"
		echo "URL: ${LAVA_JOBS_URL}/$i"
		if [ -n "${2}" ]; then
			get_test_result "$i"
		fi
		echo " "
	done
}

print_summary () {
	echo "------------------------------"
	echo "Job Summary"
	echo "------------------------------"
	for i in "${JOBS[@]}"
	do
		echo "Job #${i} ${STATUS[$i]}. Job health: ${HEALTH[$i]}. URL: ${LAVA_JOBS_URL}/${i}"
	done
}

check_status () {
	if [ -n "$TEST_TIMEOUT" ]; then
		# Current time + timeout time
		local end_time=$(date +%s -d "+ $TEST_TIMEOUT min")
	fi

	local error=false

	if [ ${#JOBS[@]} -ne 0 ]
	then

		print_status "Current job status:"
		while true
		do
			# Get latest status
			for i in "${JOBS[@]}"
			do
				if [ "${STATUS[$i]}" != "Finished" ]
				then
					local lavacli_output=${job_dir}/lavacli_output
					lavacli $LAVACLI_ARGS jobs show "$i" \
						> "$lavacli_output"

					local status=$(cat "$lavacli_output" \
						| grep "state" \
						| cut -d ":" -f 2 \
						| awk '{$1=$1};1')

					local health=$(cat "$lavacli_output" \
						| grep "Health" \
						| cut -d ":" -f 2 \
						| awk '{$1=$1};1')
					HEALTH[$i]=$health

					local device_type=$(cat "$lavacli_output" \
						| grep "device-type" \
						| cut -d ":" -f 2 \
						| awk '{$1=$1};1')
					DEVICE_TYPE[$i]=$device_type

					local device=$(cat "$lavacli_output" \
						| grep "device      :" \
						| cut -d ":" -f 2 \
						| awk '{$1=$1};1')
					DEVICE[$i]=$device

					if [ "${STATUS[$i]}" != "$status" ]; then
						STATUS[$i]=$status

						# Something has changed
						print_status "Current job status:"
					else
						STATUS[$i]=$status
					fi
				fi
			done

			if check_if_all_finished; then
				break
			fi

			if [ -n "$TEST_TIMEOUT" ]; then
				# Check timeout
				local now=$(date +%s)
				if [ "$now" -ge "$end_time" ]; then
					echo "Timed out waiting for test jobs to complete"
					error=true
					break
				fi
			fi

			# Wait to avoid spamming the server too hard
			sleep 60
		done

		if check_if_all_finished; then
			# Print job outcome
			print_status "Final job status:" true

			if check_for_test_error; then
				error=true
			fi
		fi
	fi

	if $error; then
		echo "---------------------"
		echo "Errors during testing"
		echo "---------------------"
		print_summary
		clean_up
		return 1
	fi

	echo "-----------------------------------"
	echo "All submitted tests were successful"
	echo "-----------------------------------"
	print_summary
	return 0
}

set_up
create_cip_core_jobs

if ! validate_jobs; then
	clean_up
	exit 1
fi

if ! submit_jobs; then
        clean_up
        exit 1
fi

if ! $SUBMIT_ONLY; then
	if ! check_status; then
		ERROR=true
	fi

	get_junit_test_results
fi

clean_up

if $ERROR; then
	exit 1
fi
