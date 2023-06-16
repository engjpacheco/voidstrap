#!/bin/sh

partitions () {
    cfdisk -z /dev/sda
    mkfs.vfat /dev/sda1
    mkfs.ext4 /dev/sda3
    mkswap /dev/sda2
}

mount_partitions () {
    mount /dev/sda3 /mnt
    mkdir -p /mnt/boot/efi
    mount /dev/sda1 /mnt/boot/efi
    swapon /dev/sda2
}

system_instalation () {
    export XBPS_ARCH=x86_64-musl && xbps-install -Suy -R http://mirrors.servercentral.com/voidlinux/current/musl -r /mnt \
    xbps \
    base-minimal \
    vim \
    bash \
    git \
    curl \
    ncurses \
    less \
    man-pages \
    e2fsprogs \
    procps-ng \
    pciutils \
    usbutils \
    iproute2 \
    util-linux \
    kbd \
    ethtool \
    kmod \
    traceroute \
    opendoas \
    bc \
    bgs \
    dejavu-fonts-ttf \
    dhcpcd \
    eudev \
    ffmpeg \
    file \
    gcc \
    mesa-vaapi \
    mksh \
    mpv \
    fzf \
    openssh \
    setxkbmap \
    unzip \
    xclip \
    xdotool \
    xf86-video-intel \
    xfsprogs \
    xorg-minimal \
    xrandr \
    xtools \
    xz \
    zathura-pdf-poppler \
    linux6.2 \
    dracut \
    linux-firmware-intel \
    iputils

    for dir in sys dev proc; do $(mount --rbind /$dir /mnt/$dir && mount --make-rslave /mnt/$dir); done
    cp /etc/resolv.conf /mnt/etc
    cp /etc/xbps.d/* /mnt/etc/xbps.d/
}

chroot_install () {
    chroot /mnt /bin/sh <<EOF
    ETHCARD="$(ip addr | grep ^2: | awk '{print $2}' | cut -d : -f 1)"
    xbps-install -Sy grub-x86_64-efi
    status=$?
    if [ $status -eq 16 ]; then
	xbps-install -uy xbps && xbps-install -uy grub-x86_64-efi
    fi

    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id="void"

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
    /dev/sda1   /boot/efi   vfat    defaults,noatime,nodiratime        0   2
    /dev/sda3   /           ext4    defaults,noatime,nodiratime        0   1
    /dev/sda2   swap        swap    defaults                0   0
    tmpfs       /tmp        tmpfs   defaults,nosuid,nodev,nodiratime   0   0
    #tmpfs       /home/javier/.local/src/void-packages/masterdir/builddir    tmpfs   defaults,noatime,nodiratime,size=2G    0   0" > /etc/fstab

    echo "Fstab file generated..."

    xbps-reconfigure -fa

    echo "Change root password..."
    passwd
    
    chown root:root /
    chmod 755 /	
    
    useradd -m -s /bin/mksh -U -G wheel,disk,lp,audio,video,optical,storage,scanner,network,plugdev,xbuilder javier
    
    echo "Change user password..."
    passwd javier

    echo "permit nopass root" > /etc/doas.conf
    echo "permit nopass keepenv :wheel" >> /etc/doas.conf

    rm /var/service && ln -sf /etc/runit/runsvdir/current /var/service

    # Ethernet conection:
    cp -R /etc/sv/dhcpcd-eth0 /etc/sv/dhcpcd-$ETHCARD
    sed -i 's/eth0/$ETHCARD/' /etc/sv/dhcpcd-$ETHCARD/run
    ln -s /etc/sv/dhcpcd-$ETHCARD /var/service/
    EOF
}

partitions || echo "Something went wrong, please check you partitions..."
mount_partitions || echo "Something went wrong mounting, please check you partitions..."
system_instalation && echo "Done..." || echo "Check your internet conection or the ssl verification..."
chroot_install || echo "There is an issue in the installation process..."
