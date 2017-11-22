#!/bin/bash

# Get Instance Details
instance_id=$(wget -q -O- http://169.254.169.254/latest/meta-data/instance-id)
region=$(wget -q -O- http://169.254.169.254/latest/meta-data/placement/availability-zone | sed -e 's/\([1-9]\).$/\1/g')

# Set Logging Options
logfile="/var/log/attach-ebs-volume.log"
logfile_max_lines="5000"

if [ ! $3 ]; then
  echo "Usage: $(basename $0) VOLUME_ID DEVICE MOUNT_POINT"
  echo
  echo "        VOLUME_ID - The Volume ID of the EBS volume you'd like to attach to this ec2 instance."
  echo "           DEVICE - The device location on the EC2 instance that you would like the EBS volume attached to."
  echo "                    Can be specified as 'auto' to automatically choose an available device."
  echo "      MOUNT_POINT - The location you would like the EBS Volume mounted to. (E.g. /ebs)"
  exit
fi

VOLUME_ID=$1
DEVICE=$2
MOUNT_POINT=$3
FORMAT=true

if [ -d "$MOUNT_POINT" ]; then
  echo "Warning: The mount point you specified ($MOUNT_POINT) already contains a directory"
  echo "         please ensure an EBS volume isn't already mounted at that location by checking"
  echo "         the output of the 'df' command. Otherwise if the directory is empty remove"
  echo "         it and try reattaching this EBS volume."
  exit 1
else
  mkdir /$MOUNT_POINT
fi

# Check if volume is already attached to an instance
VOLUME_ATTACHED=( $(ec2-describe-volumes --region $region $VOLUME_ID | grep "attached") )
VOLUME_ATTACHED=${VOLUME_ATTACHED[2]}

# Check if volume is attached to this instance
if [ "$VOLUME_ATTACHED" = "$instance_id" ]; then
  echo "Error: Volume is already atached to this instance."
  exit 1

# Check if volume is attached to another instance
elif [ $VOLUME_ATTACHED ]; then
  echo "Error: Volume is already attached to $VOLUME_ATTACHED"
  exit 1

# Attach volume
else
  echo "Attaching EBS Volume..."
  ec2-attach-volume $VOLUME_ID --instance $instance_id --region $region --device /dev/sdf$DEVICE_NUMBER
  echo
  # Wait for the volume to be attached before we format and mount it
  while [ ! -e /dev/sdf$DEVICE_NUMBER ]; do sleep 1; done
fi

if [ "$FORMAT" == "true" ]; then
  echo "Formatting the device with an Ext4 filesystem..."
  mkfs.ext4 /dev/sdf$DEVICE_NUMBER
  echo
fi

echo "Waiting for the volume to get ready"
sleep 10

# backup fstab file
cp /etc/fstab /etc/fstab.backup

# Get UUID
#UUID=`ls -l /dev/disk/by-uuid | grep "xvdf" | sed -n 's/^.* \([^ ]*\) -> .*$/\1/p'`
UUID=`lsblk -no UUID /dev/xvdf`
echo "UUID of the volume is ${UUID}"

echo "Checking the volume UUID in /etc/fstab file"

if [ -n "$(grep $UUID /etc/fstab)" ]; then
    echo "$UUID already exists : $(grep $UUID /etc/fstab)"
else
    echo "Adding the entry into the file"
    echo "UUID=$UUID       /eventstoredb   ext4    defaults,nofail        0       2" >> /etc/fstab
fi

# UUID=de9a1ccd-a2dd-44f1-8be8-0123456abcdef       /data   ext4    defaults,nofail        0       2

echo "Validating the file for all mount points"
mount -a

mount

## Function Declarations ##

# Function: Setup logfile and redirect stdout/stderr.
log_setup() {
    # Check if logfile exists and is writable.
    ( [ -e "$logfile" ] || touch "$logfile" ) && [ ! -w "$logfile" ] && echo "ERROR: Cannot write to $logfile. Check permissions or sudo access." && exit 1

    tmplog=$(tail -n $logfile_max_lines $logfile 2>/dev/null) && echo "${tmplog}" > $logfile
    exec > >(tee -a $logfile)
    exec 2>&1
}

# Function: Log an event.
log() {
    echo "[$(date +"%Y-%m-%d"+"%T")]: $*"
}

# Function: Confirm that the AWS CLI and related tools are installed.
prerequisite_check() {
	for prerequisite in aws wget; do
		hash $prerequisite &> /dev/null
		if [[ $? == 1 ]]; then
			echo "In order to use this script, the executable \"$prerequisite\" must be installed." 1>&2; exit 70
		fi
	done
}

## SCRIPT COMMANDS ##

log_setup
prerequisite_check
