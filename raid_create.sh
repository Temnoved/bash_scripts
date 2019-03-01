#!/usr/bin/env bash

#sudo lsblk -l | grep -E "^sd[a-z][[:space:]]"

declare -r raid_name="/dev/md0"
declare -r raid_level=5


function err()
{
  echo "[$(date +'%d-%m-%YT%H:%M%S%z')]: $@" >&2
}

function fstab_add()
{
  local raid_uuid="$(blkid | grep md0p1 | cut -d " " -f2 | tr -d "\"")"
  local fs="$(blkid | grep md0p1 | cut -d " " -f3 | tr -d "\"=[[:upper:]]")"
  echo -e "${raid_uuid}\t/srv\t${fs}\tdefaults\t0\t0" >> /etc/fstab
  return $?
}


function create_part()
{
  local curr_disk=${1}
  local partition_type=${2}
  sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' <<- _EOF_ | fdisk ${curr_disk}
o
n
p
1
 
 
t
${partition_type}
w
_EOF_

return $?
}

for i in $(lsblk -l | cut -d " " -f1 | grep -E '^(sd[b-z]$)'); do
  if
    [[ -z "$(fdisk -l /dev/${i} | grep 'label')" ]]; then
      create_part /dev/${i} "fd"
  fi
done

raid_raw=$(fdisk -l | grep "Linux" | cut -d " " -f1 | grep -E \
        "^(/dev/sd[b-z][0-9]*)")
if [[ -z ${raid_raw}  ]]; then
  err "Not devices for raid in raid_row"
fi

raid_devices=$(echo ${raid_raw})
if [[ $(echo "${raid_devices}" | wc -w) -lt 3 ]]; then
  err "There are not enought devices for RAID5"
  exit 1
fi


yum install -y mdadm
if [[ "$?" -ne 0 ]]; then
  err "Mdadm installation error"
  exit 1
fi

mdadm --create --verbose ${raid_name} --level=${raid_level}\
        --raid-devices=3 ${raid_devices}

if [[ "$?" -ne 0 ]]; then
  err "RAID5 creation error"
  exit 1
fi

#if [[ -z "$(fdisk -l | grep ${raid_name})" ]]; then
#  err "${reid_name} is not exist"
#fi

#touch /etc/mdadm.conf \
#        && chmod +w /etc/mdadm.conf \
#        && echo "DEVICE partitions" >> /etc/mdadm.conf \
#        && mdadm --detail --scan --verbose \
#        | awk '/ARRAY/ {print}' >> /etc/mdadm.conf
#if [[ "$?" -ne 0 ]]; then
#  err "Writing mdadm.conf error"
#  exit 1
#fi

create_part ${raid_name} "83"
if [[ "$?" -ne 0 ]]; then
  err "Creating partition on ${raid_name} error"
  exit 1
fi

mkfs.xfs "${raid_name}p1"
if [[ "$?" -ne 0 ]]; then
  err "Creating file system on ${raid_name}p1 error"
  exit 1
fi

fstab_add
if [[ "$?" -ne 0 ]]; then
  err "Add to fstab partition ${raid_name}p1 error"
  exit 1
fi

mount -a
if [[ "$?" -ne 0 ]]; then
  err "Mount ${raid_name}p1 error"
  exit 1
fi

dracut -f
if [[ "$?" -ne 0 ]]; then
  err "Creating new initramfs error"
  exit 1
fi

exit 0
