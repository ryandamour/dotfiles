#!/bin/bash

if [[ $# -eq 0 ]]; then
	echo "Use username as 1st argument"
	exit
elif [[ $2 -eq 0 ]]; then 
	echo "enter laptop or desktop as argument"
else
	echo "Dependency Install"
	for i in pulseaudio pavucontrol transmission xclip openssh-askpass patch i3 mutt vim firefox ansible wget git pip pip3 libvirt virt-manager qemu-kvm kernel-devel kernel-headers docker gcc dkms acpid gpg keepassx shutter libreoffice xorg-x11-drv-evdev xorg-x11-server-Xorg xorg-x11-xinit gcc gcc-c++ polkit-gnome; do dnf -y install $i; done

	echo "Install dracula vim"
        mkdir -p $1/.vim/colors/
        curl https://raw.githubusercontent.com/dracula/vim/master/colors/dracula.vim > $1/.vim/colors/dracula.vim	

	echo "HangUps Install"
	sudo /usr/bin/pip3 install hangups

	echo "gmusicapi Install"
	sudo pip install gmusicapi
        if [[ $2 -eq "desktop" ]]; then
            echo "Nvidia Install"
            wget -O /usr/local/src/NVIDIA-Linux-x86_64-375.39.run http://us.download.nvidia.com/XFree86/Linux-x86_64/375.39/NVIDIA-Linux-x86_64-375.39.run
	    chmod +x /usr/local/src/NVIDIA-Linux-x86_64-375.39.run
	    echo "blacklist nouveau" >> /etc/modprobe.d/disable-nouveau.conf
	    echo "nouveau modeset=0" >> /etc/modprobe.d/disable-nouveau.conf
	    sed -i "s/quiet/quiet rd.driver.blacklist=nouveau/" /etc/sysconfig/grub
	    grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
	    #Temporary 4.10 Nvidia Patch
	    cd /usr/local/src && ./NVIDIA-Linux-x86_64-375.39.run -x
	    cd NVIDIA-Linux-x86_64*
	    curl -O https://gist.githubusercontent.com/akofink/1024ad239e47e2e1b9d00286c4e3200b/raw/e50551a33556ade4c4b18e8f48d59971f1a055c6/kernel_4.10.patch	
	    patch -p1 < kernel_4.10.patch
        fi
	if [[ $2 -eq "laptop" ]]; then
            dnf -y install NetworkManager-wifi iwl7260-firmware 
	fi
	echo "RPMFusion Install"
	wget -O /usr/local/src/rpmfusion-free-release-26.noarch.rpm https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-26.noarch.rpm
	wget -O /usr/local/src/rpmfusion-nonfree-release-26.noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-26.noarch.rpm
	rpm -Uvh /usr/local/src/rpmfusion-free-release-26.noarch.rpm
	rpm -Uvh /usr/local/src/rpmfusion-nonfree-release-26.noarch.rpm

	echo "Install RpmFusion Applications"
	dnf -y install steam vlc

	echo "Run First-Boot Updates"
	dnf -y update
        
	echo "Xdefaults config" 
        cat .Xdefaults > $1/.Xdefaults

	echo "i3 boot"
        echo "exec i3" > $1/.xinitrc

	echo "Fix Permission"
	chown -R $1:$1 /home/$1
fi
