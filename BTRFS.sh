#!/bin/bash


#print help menu
if [ $1 == "silence" ];then
  shift 1
elif [ $# -lt 6 ] || [ $1 == "help" ];then
  echo "usage : $0 <path to drive> <drive main partition number> <kernel type> <hostname> <username> <password>"
  echo "help  : $0 help"
  exit
elif [ ! -e /sys/firmware/efi/fw_platform_size ];then
  echo WRONG BITNESS!! this script was not built for BIOS.
  exit
else
  echo this should work fine for you
fi

echo "this script assumes that partition 1 is the efi partition and you have already partitioned your system"
drive=$1
part_num=$2
ker=$3
host=$4
usr=$5
password=$6

echo $password > /password
chmod 400 /password

pacman_installable=$(cat ./pacman_installable)

#set proper split if nvme
case $drive in
  *"nvme"*)
    type="p"
    ;;
esac

efi_part="$drive""$type""1"
main_part="$drive""$type""$part_num"

#format partition
mkfs.btrfs -f -L "ARCH" $main_part
mount -t btrfs --label "ARCH" /mnt

btrfs subvolume create /mnt/@root
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
umount -R /mnt

mount -t btrfs -o defaults,x-mount.mkdir,compress=zstd,ssd,noatime,subvol=@root     LABEL="ARCH" /mnt
mount -t btrfs -o defaults,x-mount.mkdir,compress=zstd,ssd,noatime,subvol=@home     LABEL="ARCH" /mnt/home
mount -t btrfs -o defaults,x-mount.mkdir,compress=zstd,ssd,noatime,subvol=@root     LABEL="ARCH" /mnt/.snapshots

mount "$efi_part" /mnt/boot -o x-mount.mkdir

pacstrap -K /mnt $ker $ker-headers $pacman_installable

genfstab -U /mnt > /mnt/etc/fstab

cp ./chrootScript.sh /mnt
cp ./yay_installable /mnt

arch-chroot /mnt << EOF
./chrootScript.sh $ker $host $usr $password
EOF
echo COMPLETE