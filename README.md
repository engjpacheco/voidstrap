# VoidStrap installer.
A basic minimalist installer of void-musl with some packages to get ready to enjoy
this amazing GNU/Linux distro.

## Usage:

Download the iso, and once in root inside the live, git clone this repo:
``` sh
git clone https://git.disroot.org/jpacheco/voidstrap
cd voidstrap
sh install.sh
```

Once there the script will open cfdisk, and you need to format the HDD in this 
specific format:

1.- /dev/sd*X*1 -> as the boot partition.

2.- /dev/sd*X*2 -> as the swap partition.

3.- /dev/sd*X*3 -> as the root partition.

**NOTE: this needs to be in this way, if not the script will not work.**
**Make sure you do a backup of your files before doing crazy things and trust anyone script**

When the *install.sh* script finish, you need to run the postinstall script located in /root folder:
2.- postinstall.sh

This script its going to create some configuration files, like: *fstab*, *rc.conf*,
change the password of root, and add 1 user, and
some others.

``` sh
xchroot /mnt
```
Then run the *chroot.sh* script.

``` sh
sh /root/postinstall.sh
```
When the *postinsall.sh* script finishes, you only need to reboot and enjoy your
***Void-Musl*** Distro.

When it finish you need to run the *postinstall.sh* script, that is going to install
the *X server* and some other "necesary" packages.


# The custom.sh sript

This is going to install my personal dotfiles, and a specific packages that I use:
``` sh
sh /root/custom.sh
```

But you can specify your dotfiles repos and other repos that you require whit some parameters:

``` sh
sh custom.sh -r https://codeberg.org/jpacheco/dotfiles # specify a repo url.
sh custom.sh -p otherprogfile.csv # especify a custom package archive to install.
sh custom.sh -b dev # especify the name of a custom branch in case of needed.
```


