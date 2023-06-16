#!/bin/sh


xbps-install -uy xbps
xbps-install -Suy
xbps-install -y grub-x86_64-efi && grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id="void"


system_config () {
echo void > /etc/hostname

printf "
# /etc/rc.conf - system configuration for void-linux

# Set the host name.
# HOSTNAME="void"

# Set RTC to UTC or localtime.
HARDWARECLOCK="UTC"
TIMEZONE=America/Matamoros

# Keymap to load, see loadkeys(8).
KEYMAP=us\n" > /etc/rc.conf

echo "generating fstab file..."
printf "
/dev/sda1   /boot/efi   vfat    defaults,noatime        0   2
/dev/sda3   /           ext4    defaults,noatime        0   1
/dev/sda2   swap        swap    defaults                0   0
tmpfs       /tmp        tmpfs   defaults,nosuid,nodev   0   0
#tmpfs       /home/javier/.local/src/void-packages/masterdir/builddir    tmpfs   defaults,noatime,size=2G    0   0" > /etc/fstab
    echo "Fstab file generated..."


xbps-reconfigure -fa
}

users_config () {
    LANDEVICE="$(ip addr | grep ^2: | awk '{print $2}' | cut -d : -f1)"
    echo "Change root password..."
    passwd
    chown root:root /
    chmod 755 /	
    useradd -m -U -G wheel,disk,lp,audio,video,optical,storage,scanner,network,plugdev,xbuilder javier
    echo "Change user password..."
    passwd javier

    echo "permit nopass root" > /etc/doas.conf
    echo "permit nopass keepenv :wheel" >> /etc/doas.conf

    rm /var/service && ln -sf /etc/runit/runsvdir/current /var/service

    # Ethernet conection:
    cp -R /etc/sv/dhcpcd-eth0 /etc/sv/dhcpcd-$LANDEVICE
    sed -i 's/eth0/enp0s3/' /etc/sv/dhcpcd-$LANDEVICE/run
    ln -s /etc/sv/dhcpcd-$LANDEVICE /var/service/
}

system_config
users_config
