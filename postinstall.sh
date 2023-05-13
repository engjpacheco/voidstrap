#!/bin/sh

while getopts ":a:r:b:p:h" o; do case "${o}" in
	h) printf "Optional arguments for custom use:\\n  -r: Dotfiles repository (local file or url)\\n  -p: Dependencies and programs csv (local file or url)\\n  -h: Show this message\\n" && exit ;;
	r) dotfilesrepo=${OPTARG} && git ls-remote "$dotfilesrepo" || exit ;;
	b) repobranch=${OPTARG} ;;
	p) progsfile=${OPTARG} ;;
	*) printf "Invalid option: -%s\\n" "$OPTARG" && printf "Optional arguments for custom use:\\n  -r: Dotfiles repository (local file or url)\\n  -p: Dependencies and programs csv (local file or url)\\n  -h: Show this message\\n" && exit ;;
esac done

[ -z "$dotfilesrepo" ] && dotfilesrepo="https://codeberg.org/javier_pacheco/voidots"
[ -z "$progsfile" ] && progsfile="https://codeberg.org/javier_pacheco/voidstrap/raw/branch/main/progs.csv"
[ -z "$repobranch" ] && repobranch="main"

### FUNCTIONS ###

installpkg(){ xbps-install -y "$1" >/dev/null 2>&1 ;}
grepseq="\"^[PGV]*,\""

error() { clear; printf "ERROR:\\n%s\\n" "$1"; exit;}

welcomemsg() { \
	dialog --title "Welcome!" --msgbox "Welcome to Auto Void SetUp Script!\\n\\nThis script will automatically install a fully-featured Void Linux desktop, which I use as my main machine.\\n\\n-Javier Pacheco" 10 60
	}

getuser() { \
	# Prompts user for their username.
	name=$(dialog --inputbox "First, please enter the username you created during the Void Linux install process." 10 60 3>&1 1>&2 2>&3 3>&1) || exit
	repodir="/home/$name/repos"; doas -u $name mkdir -p "$repodir"
	while ! echo "$name" | grep "^[a-z_][a-z0-9_-]*$" >/dev/null 2>&1; do
		name=$(dialog --no-cancel --inputbox "Username not valid. Be sure your username contains valid characters: lowercase letters, - or _." 10 60 3>&1 1>&2 2>&3 3>&1)
	done ;}

preinstallmsg() { \
	dialog --title "Enter The Void..." --yes-label "Let's go!" --no-label "No, nevermind!" --yesno "The rest of the installation will now be totally automated, so you can sit back and relax.\\n\\nIt will take some time, but when done, you can relax even more with your complete system.\\n\\nNow just press <Let's go!> and the system will begin installation!" 13 60 || { clear; exit; }
	}

maininstall() { # Installs all needed programs from main repo.
	dialog --title "Main Installation" --infobox "Installing \`$1\` ($n of $total). $1 $2" 5 70
	installpkg "$1"
	}

gitmakeinstall() {
	progname="$(basename "$1")"
	dir="$repodir/$progname"
	dialog --title "Main Installation" --infobox "Installing \`$progname\` ($n of $total) via \`git\` and \`make\`. $(basename "$1") $2" 5 70
	doas -u "$name" git clone --depth 1 "$1" "$dir" >/dev/null 2>&1 || { cd "$dir" || return ; doas -u "$name" git pull --force origin main;}
	cd "$dir" || exit
	make >/dev/null 2>&1
	make install >/dev/null 2>&1
	cd /tmp || return ;}

pipinstall() { \
	dialog --title "Main Installation" --infobox "Installing the Python package \`$1\` ($n of $total). $1 $2" 5 70
	command -v pip || installpkg python-pip >/dev/null 2>&1
	yes | pip install "$1"
	}

installationloop() { \
	([ -f "$progsfile" ] && cp "$progsfile" /tmp/progs.csv) || curl -Ls -k "$progsfile" | sed '/^#/d' | eval grep "$grepseq" > /tmp/progs.csv
	total=$(wc -l < /tmp/progs.csv)
	while IFS=, read -r tag program comment; do
		n=$((n+1))
		echo "$comment" | grep "^\".*\"$" >/dev/null 2>&1 && comment="$(echo "$comment" | sed "s/\(^\"\|\"$\)//g")"
		case "$tag" in
			"G") gitmakeinstall "$program" "$comment" ;;
			"P") pipinstall "$program" "$comment" ;;
			*) maininstall "$program" "$comment" ;;
		esac
	done < /tmp/progs.csv ;}

putgitrepo() { # Downloads a gitrepo $1 and places the files in $2 only overwriting conflicts
	dialog --title "Installing dotfiles" --infobox "Downloading and installing config files..." 4 60
	dir=$(mktemp -d)
	[ ! -d "$2" ] && mkdir -p "$2"
	chown -R "$name:wheel" "$dir" "$2"
	git clone "$1" "$dir" >/dev/null 2>&1
	doas -u "$name" cp -rfT "$dir" "$2"
	}

finalize(){ \
	dialog --infobox "Preparing welcome message..." 4 50
	dialog --title "All done!" --msgbox "Congrats! Provided there were no hidden errors, the script completed successfully and all the programs and configuration files should be in place.\\n\\nTo run the new graphical environment, log out and log back in as your new user, then run the command \"startx\" to start the graphical environment (it will start automatically in tty1).\\n\\n.t Ole" 12 80
	}

### THE ACTUAL SCRIPT ###

### This is how everything happens in an intuitive format and order.

# Check if user is root on Arch distro. Install dialog.
installpkg dialog || error "Are you sure you're running this as the root user and have an internet connection?"

# Welcome user and pick dotfiles.
welcomemsg || error "User exited."

# Get and verify username and password.
getuser || error "User exited."

# Last chance for user to back out before install.
preinstallmsg || error "User exited."

dialog --title "Main Installation" --infobox "Installing \`Void nonfree repo\`, \`basedevel\` and \`git\`. These are required for the installation of other software." 5 70

# Change the mirros from default to chicago
if [ ! -d /etc/xbps.d ] 
then
	mkdir -p /etc/xbps.d
fi

cp /usr/share/xbps.d/*-repository-*.conf /etc/xbps.d/
# if this dont update the systeme mirrors, change https for http in the second argument in sed.
sed -i 's|https://repo-default.voidlinux.org|http://mirrors.servercentral.com/voidlinux/|g' /etc/xbps.d/*-repository-*.conf

installpkg void-repo-nonfree
xbps-install -Suy >/dev/null 2>&1
installpkg base-devel 
installpkg git

# Install the dotfiles in the user's home directory
# i do it manualy so...
putgitrepo $dotfilesrepo "/home/$name/.dotfiles"

# Create basic home directories
doas -u $name mkdir -p /home/$name/docs /home/$name/dwls /home/$name/vids /home/$name/music /home/$name/pics
doas -u $name mkdir -p /home/$name/.cache/zsh/ && cd /home/$name/.cache/zsh && doas -u $name touch history

# The command that does all the installing. Reads the progs.csv file and
# installs each needed program using either xbps or git.
installationloop

# Make zsh the default shell for the user
chsh -s /bin/zsh $name

# Disable ttys 3-6
for i in $(seq 3 6)
do
  rm -rf /var/service/agetty-tty$i >/dev/null 2>&1
  touch /etc/sv/agetty-tty$i/down >/dev/null 2>&1
done

# Enable tap to click
[ ! -f /etc/X11/xorg.conf.d/40-libinput.conf ] && mkdir -p /etc/X11/xorg.conf.d && printf 'Section "InputClass"
        Identifier "libinput touchpad catchall"
        MatchIsTouchpad "on"
        MatchDevicePath "/dev/input/event*"
        Driver "libinput"
	# Enable left mouse button by tapping
	Option "Tapping" "on"
EndSection' >/etc/X11/xorg.conf.d/40-libinput.conf

# install libXft patched for color emojis support because why not...
doas xbps-install -R /home/$name/.dotfiles/libXft-void_patch -f libXft -y >/dev/null

# create symbolic links to config and local folders
for folder in /home/$name/.dotfiles/home/.config /home/$name/.dotfiles/home/.local
do
  ln -sf $folder /home/$name/
done

# create symbolic links to x profile and z profile
ln -sf /home/$name/.dotfiles/home/.config/x11/xprofile /home/$name/.xprofile
ln -sf /home/$name/.dotfiles/home/.config/shell/profile /home/$name/.zprofile

# autologin in tty1
sed -i 's|GETTY_ARGS="--noclear"|GETTY_ARGS="--autologin javier --noclear"|g' /etc/sv/agetty-tty1/conf

# Last message! Install complete!
finalize
clear
