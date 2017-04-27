#!/bin/bash

if [[ $# -eq 0 ]]; then
	echo "Use username as 1st argument"
	exit
else
	echo "Dependency Install"
	for i in transmission xclip openssh-askpass patch i3 mutt vim firefox ansible wget git pip pip3 libvirt virt-manager qemu-kvm kernel-devel kernel-headers docker gcc dkms acpid gpg keepassx shutter libreoffice xorg-x11-drv-evdev xorg-x11-server-Xorg xorg-x11-xinit gcc gcc-c++; do dnf -y install $i; done

	echo "Vim Solarized Install"
	mkdir -p /home/$1/.vim/colors/
	/usr/bin/wget -O /home/$1/.vim/colors/solarized.vim https://raw.githubusercontent.com/altercation/vim-colors-solarized/master/colors/solarized.vim
	
	echo "urvxt Solarized Install"
	wget -O /home/$1/.Xdefaults https://gist.githubusercontent.com/yevgenko/1167205/raw/12d26d2c65d991850796c708fb737dd8a453de8b/.Xdefaults
	
	echo "HangUps Install"
	sudo /usr/bin/pip3 install hangups

	echo "gmusicapi Install"
	sudo pip install gmusicapi
	
	echo "Nvidia Install"
	wget -O /usr/local/src/NVIDIA-Linux-x86_64-375.39.run http://us.download.nvidia.com/XFree86/Linux-x86_64/375.39/NVIDIA-Linux-x86_64-375.39.run
	chmod +x /usr/local/src/NVIDIA-Linux-x86_64-375.39.run
	echo "blacklist nouveau" >> /etc/modprobe.d/disable-nouveau.conf
	echo "nouveau modeset=0" >> /etc/modprobe.d/disable-nouveau.conf
	sed -i "s/quiet/quiet rd.driver.blacklist=nouveau/" /etc/sysconfig/grub
	grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
	 Temporary 4.10 Nvidia Patch
	cd /usr/local/src && ./NVIDIA-Linux-x86_64-375.39.run -x
	cd NVIDIA-Linux-x86_64*
	curl -O https://gist.githubusercontent.com/akofink/1024ad239e47e2e1b9d00286c4e3200b/raw/e50551a33556ade4c4b18e8f48d59971f1a055c6/kernel_4.10.patch	
	patch -p1 < kernel_4.10.patch

	echo "RPMFusion Install"
	wget -O /usr/local/src/rpmfusion-free-release-25.noarch.rpm https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-25.noarch.rpm
	wget -O /usr/local/src/rpmfusion-nonfree-release-25.noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-25.noarch.rpm
	rpm -Uvh /usr/local/src/rpmfusion-free-release-25.noarch.rpm
	rpm -Uvh /usr/local/src/rpmfusion-nonfree-release-25.noarch.rpm

	echo "Install RpmFusion Applications"
	dnf -y install steam vlc

	echo "Run First-Boot Updates"
	dnf -y update

	echo "Fix Vim Arrow Mappings"
	echo "!! Fix Control+Arrow Key Mapping" >> /home/$1/.Xdefaults 
	echo "URxvt.keysym.Control-Up:   \033[1;5A" >> /home/$1/.Xdefaults
	echo "URxvt.keysym.Control-Down:    \033[1;5B" >> /home/$1/.Xdefaults
	echo "URxvt.keysym.Control-Left:    \033[1;5D" >> /home/$1/.Xdefaults
	echo "URxvt.keysym.Control-Right:    \033[1;5C" >> /home/$1/.Xdefaults

	echo "Control+Shift+c/v for Copy/Paste"
	cp clipboard /usr/lib64/urxvt/perl/
	echo "!! Add Control+Shift+c/v for Copy/Paste" >> /home/$1/.Xdefaults
	echo "URxvt.keysym.Shift-Control-V: perl:clipboard:paste" >> /home/$1/.Xdefaults
	echo "URxvt.iso14755: False" >> /home/$1/.Xdefaults
	echo "URxvt.perl-ext-common: default,clipboard" >> /home/$1/.Xdefaults

	echo "Fix Permission"
	chown -R $1:$1 /home/$1
fi
