#!/bin/bash

mkfs.ext4 -f $main_part

mount $main_part /mnt
mount --mkdir $efi_part /mnt/boot
