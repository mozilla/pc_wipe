#! /usr/bin/env bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

# This script should only be executed under Linux from a bootable USB/CD.
# This script wipes all detected internal drives by using dd to write zeros (one-pass) to the drives.

# A list that contains the name and size of all internal drive(s). 
DRIVE_LIST=$(lsblk -do NAME,SIZE,RM | awk 'NR == 1 || $3 == 0 && $1 ~/sd/ {print $1 "\t" $2}')

# The script will exit if no internal drives are found.
DRIVE_NUMBER=$(echo $DRIVE_LIST | wc -w)
if [[ "${DRIVE_NUMBER}" == "2" ]] ; then
	echo "No drives found."	
	exit 131
fi

# Display the name and size of all detected internal drives.
echo -e "\n$DRIVE_LIST\n"

# Confirm to proceed with wiping all detected internal drives.
echo -e "WARNING: The drive(s) above will be wiped and all data will be lost. Please type \"YES\" to proceed.\n"
read CONTINUE

if [[ "${CONTINUE}" == "YES" ]] ; then
	DRIVE_NAME=$(lsblk -do NAME,RM | awk '$2 == "0" && $1 ~/sd/ {print $1}')
	for DRIVE in $DRIVE_NAME ; do
		echo -e "\nWiping /dev/$DRIVE..."
		DISK_SIZE=$(lsblk -bdno SIZE /dev/$DRIVE)
		BLOCK_SIZE=4096
		BLOCK_COUNT=$(($DISK_SIZE / $BLOCK_SIZE))
# If Pipe Viewer (pv) doesn't exist, the ETA of the wipe session will not be displayed		
		if hash pv 2> /dev/null ; then
			dd if=/dev/zero | pv -petrbs $DISK_SIZE | dd of=/dev/$DRIVE bs=$BLOCK_SIZE count=$BLOCK_COUNT iflag=fullblock status=none || {
				echo -e "\nFailed to wipe /dev/$DRIVE"
				exit 132
			}
		else
			dd if=/dev/zero of=/dev/$DRIVE bs=$BLOCK_SIZE count=$BLOCK_COUNT iflag=fullblock status=none || {
				echo -e "\nFailed to wipe /dev/$DRIVE"
				exit 133
			}
		fi
		echo -e "\n/dev/$DRIVE has been wiped."
	done
else
	echo "A confirmation to proceed was not provided. No changes have been made."
	exit 134
fi
