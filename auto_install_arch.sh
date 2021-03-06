#!/bin/bash

set -ef


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
  n # new partition
  p # primary partition
  1 # partition number 1
    # default - start at beginning of disk
    # default - start at ending of disk
  p # print the in-memory partition table
  w # write the partition table
  q # and we're done
EOF

mkfs.ext4 /dev/sda1
mount /dev/sda1 /mnt

#--------------------------------------------------------------------
# install base base-devel package
#--------------------------------------------------------------------
pacstrap /mnt base base-devel

#--------------------------------------------------------------------
# configure the system
#--------------------------------------------------------------------
# fstab
genfstab -U /mnt >> /mnt/etc/fstab

# chroot
arch-chroot /mnt

# setup timezone
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# setup locale
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8"

# setup hosts
echo "127.0.0.1	localhost\
::1		localhost\
127.0.1.1	arch.localdomain	arch" >> /etc/hosts

# install bootloader
echo 'Installing bootloader'
pacman -S grub --noconfirm
grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

#--------------------------------------------------------------------
# user config
#--------------------------------------------------------------------
# add user
user="jocoo"
password=${user}
useradd -m -g wheel -s /bin/bash ${user} &>/dev/null ||
    usermod -a -G wheel ${user} && mkdir -p /home/${user} && \
    chown ${user}:wheel /home/${user}

# change password
echo "${user}:${password}" | chpasswd
echo "root:archlinux" | chpasswd

# add user to sudoers
sed -i "s/^# \(%wheel ALL=(ALL) ALL\)/\1/" /etc/sudoers

# install dev envt.
echo 'Installing dev environment'
pacman -S --noconfirm git emacs nodejs npm vim gvim wget curl make gcc grep \
  xorg-server xorg-xinit i3 gdm dmenu chromium autojump openssh sudo \
  the_silver_searcher ttf-hack adobe-source-code-pro-fonts otf-fira-code \
  termite ntp networkmanager keychain python3 python-pip shadowsocks-libev \
  feh compton htop
npm install -g eshint webpack live-server prettier express
pip install pipenv ipython requests

# setup i3
cd /home/${user}
git clone https://github.com/Jocoo0326/dwm.git
cd dwm && ./auto.sh && cd ..
git clone https://github.com/Jocoo0326/st.git
cd st && ./auto.sh && cd ..
echo "exec dwm &" > .xinitrc
chown -R ${user} /home/${user}

# enable services
systemctl enable gdm.service ntpdate.service NetworkManager.service

exit
echo "done"
