#!/bin/bash

#list drives
DRIVE_LIST=($(ls /dev | grep -x -e "nvme0n[0-9]" -e "sd[a-z]"))
DRIVE_LIST_N=${#DRIVE_LIST[@]}
echo this script assumes you have already partitioned the hard drive
echo
echo

read -p "PRESS ENTER TO CONTINUE"

PROGRESS=""

clear
echo what drive are you installing on?
select ENTRYA in ${DRIVE_LIST[@]}
do
  if [ $REPLY -lt $(( $DRIVE_LIST_N + 1 )) ];then
    MAIN_DRIVE="/dev/$ENTRYA"
    break
  else
    echo INVALID ENTRY: TRY AGAIN
  fi
done
PROGRESS+="DRIVE PATH : $MAIN_DRIVE\n"
clear

PARTITION_LIST=($(ls /dev | grep -e "$ENTRYA\(p\)\?[0-9]"))
PARTITION_LIST_N=${#PARTITION_LIST[@]}

echo -e $PROGRESS
echo
echo where is your EFI partition?
select ENTRYB in ${PARTITION_LIST[@]}
do
  if [ $REPLY -lt $(( $PARTITION_LIST_N + 1 )) ];then
    EFI_DRIVE="/dev/$ENTRYB"
    break
  else
    echo INVALID ENTRY: TRY AGAIN
  fi
done
PROGRESS+="EFI PATH   : $EFI_DRIVE\n"
clear

echo -e $PROGRESS
echo
echo where do you want to install?
select ENTRYC in ${PARTITION_LIST[@]}
do
  if [ $REPLY -lt $(( $PARTITION_LIST_N + 1 )) ];then
    ROOT_DRIVE="/dev/$ENTRYC"
    if [ $EFI_DRIVE == $ROOT_DRIVE ];then
      echo YOUR EFI MUST BE SEPERATE FROM YOUR ROOT DRIVE!
    else
      break
    fi
  else
    echo INVALID ENTRY: TRY AGAIN
  fi
done
PROGRESS+="ROOT PATH  : $ROOT_DRIVE\n"
clear


echo -e $PROGRESS

K_LIST=("linux" "linux-zen" "linux-lts" "linux-rt" "linux-rt-lts")
K_LIST_N=${#K_LIST[@]}

select ENTRYD in ${K_LIST[@]}
do
  if [ $REPLY -lt $(( $K_LIST_N + 1 )) ]; then
    KERNEL=$ENTRYD
    break
  else
    echo INVALID ENTRY: TRY AGAIN
  fi
done
PROGRESS+="KERNEL : $KERNEL\n"
clear


#$MAIN_DRIVE
#$EFI_DRIVE
#$ROOT_DRIVE
#$KERNEL
#are defined by the above functions


echo -e $PROGRESS
read -p  "enter hostname : " HOSTNAME
PROGRESS+="HOSTNAME   : $HOSTNAME\n"
clear
echo -e $PROGRESS
read -p  "enter username : " USERNAME
PROGRESS+="USERNAME   : $USERNAME\n"
clear
echo -e $PROGRESS
read -sp "enter password : " PASSWORD
PROGRESS+="PASSWORD  : good\n"
clear
echo -e $PROGRESS
echo $PASSWORD >> /passwd
chmod 400 /passwd

echo


read -p  "enter filesystem (btrfs, ext4) : " FILESYSTEM
case "$FILESYSTEM" in
  "ext"*)
    PROGRESS+="FILESYSTEM: EXT4"
    clear
    echo -e $PROGRESS
    read -p "PRESS ENTER TO CONTINUE"

    mkfs.ext4 -f $main_part

    mount $main_part /mnt
    mount --mkdir $efi_part /mnt/boot
    SUBVOL=""
    ;;
  "btr"*)
    PROGRESS+="FILESYSTEM: BTRFS"
    clear
    echo -e $PROGRESS
    read -p "PRESS ENTER TO CONTINUE"

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

    SUBVOL="rootflags=subvol=@root "
    ;;
esac



pacstrap -K /mnt $KERNEL $KERNEL-headers $(cat ./pacman_installable)

genfstab -U /mnt > /mnt/etc/fstab

cp ./chrootScript.sh /mnt
cp ./yay_installable /mnt

arch-chroot /mnt << EOF
./chrootScript.sh $KERNEL $HOSTNAME $USERNAME $PASSWORD $ROOT_DRIVE $SUBVOL
EOF
echo COMPLETE
