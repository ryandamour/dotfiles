#!/bin/bash
echo "Dependency Install"
for i in i3 mutt vim firefox ansible git pip pip3 libvirt virt-manager qemu-kvm kernel-devel kernel-headers docker gcc dkms acpid gpg keepassx shutter libreoffice; do dnf -y install $i; done

echo "Vim Solarized Install"
mkdir -p ~/.vim/colors/
/usr/bin/wget -O ~/.vim/colors/solarized.vim https://raw.githubusercontent.com/altercation/vim-colors-solarized/master/colors/solarized.vim

echo "urvxt Solarized Install"
wget -O ~/.Xresources https://gist.githubusercontent.com/yevgenko/1167205/raw/12d26d2c65d991850796c708fb737dd8a453de8b/.Xdefaults

echo "HangUps Install"
sudo /usr/bin/pip3 install hangups

echo "gmusicapi Install"
sudo pip install gmusicapi
echo "Nvidia Install"
wget -O /usr/local/src/NVIDIA-Linux-x86_64-375.39.run http://us.download.nvidia.com/XFree86/Linux-x86_64/375.39/NVIDIA-Linux-x86_64-375.39.run
chmod +x /usr/local/src/NVIDIA-Linux-x86_64-375.39.run
echo "blacklist nouveau" >> /etc/modprobe.d/disable-nouveau.conf
echo "nouveau modeset=0" >> /etc/modprobe.d/disable-nouveau.conf
sed -i "s/rhgb/rdblacklist=nouveau rhgb " /boot/grub2/grub.cfg
cd /usr/local/src && ./NVIDIA-Linux-x86_64-375.39.run
systemctl set-default graphical.target

echo "RPMFusion Install"
wget -O /usr/local/src/rpmfusion-free-release-25.noarch.rpm https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-25.noarch.rpm
wget -O /usr/local/src/rpmfusion-nonfree-release-25.noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-25.noarch.rpm
rpm -Uvh /usr/local/src/rpmfusion-free-release-25.noarch.rpm
rpm -Uvh /usr/local/src/rpmfusion-nonfree-release-25.noarch.rpm

echo "Install Steam"
dnf -y install steam
