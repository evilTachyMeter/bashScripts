#!/bin/bash

ker=$1
host=$2
usr=$3
password=$4
main_drive=$5
btrfs_state=$6

echo $password > /password
chmod 400 /password
ln -sf /usr/share/zoneinfo/America/Denver /etc/localtime
hwclock --systohc
sed -i 's/#en_US/en_US/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF8" > /etc/locale.conf
echo $host > /etc/hostname
sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
mkinitcpio -P
echo -e "$password\n$password" | passwd
useradd -m -G wheel,storage,power -g users -s /usr/bin/zsh tmpusr
echo -e "$password\n$password" | passwd tmpusr
sudo -H -u tmpusr zsh -c 'cd ~; git clone https://aur.archlinux.org/yay.git; cd yay; sudo -S ls; makepkg -is --noconfirm'
userdel -fr tmpusr
useradd -m -G wheel,storage,power -g users -s /usr/bin/zsh $usr
echo -e "$password\n$password" | passwd $usr
systemctl enable NetworkManager
bootctl install
cat > /boot/loader/loader.conf << EOF
default arch.conf
timeout 4
console-mode max
editor no
EOF
cat > /boot/loader/entries/arch.conf << EOF
title arch linux
linux /vmlinuz-$ker
initrd /intel-ucode.img
initrd /amd-ucode.img
initrd /initramfs-$ker.img
options root=$main_drive ${btrfs_state}rw
EOF
