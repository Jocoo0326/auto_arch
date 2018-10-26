#!/bin/bash

set -e

#--------------------------------------------------------------------
# add tsinghua mirror address to pacman config file then sync pacman
#--------------------------------------------------------------------
TSING_HUA_MIRROR='Server = http://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch'
PACMAN_MIRROR_LIST_FILE='/etc/pacman.d/mirrorlist'
modify_pacman_mirror_list_file_and_sync() {
  echo "config pacman mirror"
  server_first_occur_line=$(sed -n '/Server /=' ${PACMAN_MIRROR_LIST_FILE} | head -n 1)
  echo "$(sed "${server_first_occur_line} c${TSING_HUA_MIRROR}" ${PACMAN_MIRROR_LIST_FILE})" > ${PACMAN_MIRROR_LIST_FILE}
  pacman -Sy
}

modify_pacman_mirror_list_file_and_sync


#--------------------------------------------------------------------
# partition and format disk, mount the file systems
#--------------------------------------------------------------------
sed -e "s/\s*\([\+0-9a-zA-Z]*\).*/\1/" << EOF | fdisk /dev/sda
  p # print the in-memory partition table
  o # clear the in memory partition table
  n # new partition
  p # primary partition
  1 # partition number 1
    # default - start at beginning of disk
    # default - start at ending of disk
  p # print the in-memory partition table
  w # write the partition table
  q # and we're done
EOF

#--------------------------------------------------------------------
# 
#--------------------------------------------------------------------
