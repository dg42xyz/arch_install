# Increate console font size
echo 'FONT=latarcyrheb-sun32' > /etc/vconsole.conf
systemctl restart systemd-vconsole-setup

# Connect to the internet
ip link
# ip link set <interface> up
# Or for wireless
# wifi-menu

# Verify network connection
ping archlinux.org

# Update the system clock
timedatectl set-ntp true

# Partition the disks
cgdisk /dev/nvme0n1
# 1 512MB EFI partition # Hex code ef00
# 2 512MB Boot partition # Hex code 8300
# 3 100% size partiton # (to be encrypted) Hex code 8300

# Format the partitions
mkfs.vfat -F32 /dev/nvme0n1p1
mkfs.ext2 /dev/nvme0n1p2

# Setup the encryption of the system
cryptsetup -c aes-xts-plain64 -s 512 -y --use-random luksFormat /dev/nvme0n1p3
cryptsetup luksOpen /dev/nvme0n1p3 luks

# Create encrypted partitions
pvcreate /dev/mapper/luks
vgcreate vg0 /dev/mapper/luks
lvcreate --size 16G vg0 --name swap
lvcreate --size 64G vg0 --name root
lvcreate -l +100%FREE vg0 --name home

# Create filesystems on encrypted partitions
mkfs.ext4 /dev/mapper/vg0-root
mkfs.ext4 /dev/mapper/vg0-home
mkswap /dev/mapper/vg0-swap

# Mount the file systems
mount /dev/mapper/vg0-root /mnt
swapon /dev/mapper/vg0-swap
mkdir /mnt/boot
mount /dev/nvme0n1p2 /mnt/boot
mkdir /mnt/boot/efi
mount /dev/nvme0n1p1 /mnt/boot/efi
mkdir /mnt/home
mount /dev/mapper/vg0-home /mnt/home

# Select the mirrors
curl -o /etc/pacman.d/mirrorlist "https://www.archlinux.org/mirrorlist/?country=US&protocol=https&ip_version=4&use_mirror_status=on"
sed -i 's/\#Server/Server/g' /etc/pacman.d/mirrorlist

# Install essential packages and optional tools
pacstrap /mnt base base-devel linux linux-firmware vi vim git efibootmgr dialog wpa_supplicant iw sudo binutils

# Generate fstab file
genfstab -pU /mnt >> /mnt/etc/fstab

# Make /tmp a ramdisk
echo 'tmpfs	/tmp	tmpfs	defaults,noatime,mode=1777	0	0' >> /mnt/etc/fstab

# Chroot to new system
arch-chroot /mnt /bin/bash

# Set the time zone
ln -s /usr/share/zoneinfo/America/New_York /etc/localtime
hwclock --systohc --utc

# Localization
echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
echo 'en_US ISO-8859-1' >> /etc/locale.gen
echo 'LANG=en_US.UTF-8' >> /etc/locale.conf
echo 'LANGUAGE=en_US' >> /etc/locale.conf
locale-gen

# Persist console font
echo 'FONT=latarcyrheb-sun32' > /etc/vconsole.conf

# Set the hostname
echo 'hello' > /etc/hostname

# Update hosts file
echo '127.0.0.1  localhost' >> /etc/hosts
echo '::1        localhost' >> /etc/hosts
echo '127.0.0.1  hello.localdomain hello' >> /etc/hosts

# Root password
passwd

# Add unprivileged user
useradd -m -g users -G wheel dg
passwd dg

# Edit /etc/suders, uncomment
# %wheel ALL=(ALL) ALL

# Generate a keyfile and add it as a LUKS key
dd bs=512 count=8 if=/dev/random of=/boot/crypto_keyfile.bin iflag=fullblock
chmod 600 /boot/crypto_keyfile.bin
chmod 600 /boot/initramfs-linux*
cryptsetup luksAddKey /dev/mapper/luks /boot/crypto_keyfile.bin

# Configure mkinitcpio
vim /etc/mkinitcpio.conf
# MODULES=(ext4 i915)
# HOOKS=(base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt sd-lvm2 resume filesystems fsck)
# FILES=(/crypto_keyfile.bin)

# Regenerate mkinitcpio/initramfs image
mkinitcpio -p linux

# Set up systemd-boot
bootctl --path=/boot/efi install

# Enable Intel microcode updates
pacman -S intel-ucode

# Create boot loader entry
UUID=$(echo $(blkid | grep nvme0n1p3 | cut -d '"' -f 2))
cat <<EOF > /boot/efi/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options rd.luks.uuid=#UUID rd.luks.key=/boot/crypto_keyfile.bin root=/dev/mapper/vg0-root resume=/dev/mapper/vg0-swap quiet mem_sleep_default=deep rw splash
EOF
sed -i "s/\#UUID/$UUID/g" /boot/efi/loader/entries/arch.conf

# Loader configuration
cat <<EOF > /boot/efi/loader/loader.conf
default  arch
timeout  5
editor   no
EOF

# Create systemd-boot-pacman hook
cat <<EOF > /etc/pacman.d/hooks/systemd-boot.hook
[Trigger]
Type = Package
Operation = Upgrade
Target = systemd

[Action]
Description = Updating systemd-boot...
When = PostTransaction
Exec = /usr/bin/bootctl --path=/boot/efi update
EOF

# Exit chroot
exit

# Unmount all partitions
umount -R /mnt
swapoff -a

# Reboot into the new system
reboot
