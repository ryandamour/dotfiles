#!/bin/bash

if [[ $# -eq 0 ]]; then
	echo "Use username as 1st argument"
	exit
elif [[ $# -lt 2 ]]; then 
	echo "enter laptop or desktop as argument"
else
	echo "Dependency Install"
	for i in pulseaudio pavucontrol transmission xclip openssh-askpass patch i3 mutt vim firefox ansible wget git pip pip3 libvirt virt-manager qemu-kvm kernel-devel kernel-headers docker gcc dkms acpid gpg keepassx shutter libreoffice xorg-x11-drv-evdev xorg-x11-server-Xorg xorg-x11-xinit gcc gcc-c++ polkit-gnome; do dnf -y install $i; done
        dnf -y groupinstall base-x
	
	echo "Install dracula vim"
        mkdir -p /home/$1/.vim/colors/
        curl https://raw.githubusercontent.com/dracula/vim/master/colors/dracula.vim > $1/.vim/colors/dracula.vim	

	echo "HangUps Install"
	sudo /usr/bin/pip3 install hangups

	echo "gmusicapi Install"
	sudo pip install gmusicapi
	
	if [[ $2 = "laptop" ]]; then
            dnf -y install NetworkManager-wifi iwl7260-firmware 
	fi
	
	echo "Run First-Boot Updates"
	dnf -y update
	
	echo "Negativo17 Install"
	dnf config-manager --add-repo=https://negativo17.org/repos/fedora-nvidia.repo
	
	echo "Install Nvidia drivers"
	dnf install nvidia-driver kernel-devel akmod-nvidia dkms acpi
	
	echo "Enable bumblee"
	dnf copr enable chenxiaolong/bumblebee
	dnf install akmod-bbswitch bumblebee primus

        echo "Make user part of bumblee group"
	gpasswd -a $1 bumblebee
        
	echo "enable bumblee / disable nvidia-fallback
	systemctl enable bumblebeed
	systemctl disable nvidia-fallback
	
	echo "Xdefaults config" 
        cp .Xdefaults > /home/$1/.Xdefaults
	
	echo "Move clipboard to /usr/lib64/urxvt/perl"
	cp clipboard /usr/lib64/urxvt/perl

	echo "i3 boot"
        echo "exec i3" > /home/$1/.xinitrc

	echo "Fix Permission"
	chown -R $1:$1 /home/$1
fi
