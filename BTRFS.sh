#!/bin/bash

EFI_DRIVE=$1
ROOT_DRIVE=$2


mkfs.btrfs -f -L "ARCH" $ROOT_DRIVE
mount -t btrfs --label "ARCH" /mnt

btrfs subvolume create /mnt/@root
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
umount -R /mnt

mount -t btrfs -o defaults,x-mount.mkdir,compress=zstd,ssd,noatime,subvol=@root     LABEL="ARCH" /mnt
mount -t btrfs -o defaults,x-mount.mkdir,compress=zstd,ssd,noatime,subvol=@home     LABEL="ARCH" /mnt/home
mount -t btrfs -o defaults,x-mount.mkdir,compress=zstd,ssd,noatime,subvol=@root     LABEL="ARCH" /mnt/.snapshots

mount "$EFI_DRIVE" /mnt/boot -o x-mount.mkdir
