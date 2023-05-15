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
    base-devel \
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

    for i in sys dev proc; do $(mount --rbind /$i /mnt/$i && mount --make-rslave /mnt/$i); done
    cp /etc/resolv.conf /mnt/etc
    cp /etc/xbps.d/* /mnt/etc/xbps.d/
}

partitions || echo "Something went wrong, please check you partitions..."
mount_partitions || echo "Something went wrong mounting, please check you partitions..."
system_instalation && echo "Done..." || echo "Check your internet conection or the ssl verification..."
