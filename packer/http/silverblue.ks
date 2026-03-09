# Kickstart for Fedora Silverblue 42 — Vagrant base box
# Unattended install via ostreecontainer (modern approach, no %packages)

# System language and keyboard
lang en_US.UTF-8
keyboard us
timezone UTC

# Network
network --bootproto=dhcp --device=link --activate --onboot=on

# Security — throwaway test VM
firewall --disabled
selinux --enforcing

# Auth
rootpw --plaintext vagrant

# Disk
zerombr
clearpart --all --initlabel
autopart --type=plain --nohome

# Bootloader — console=ttyS0 so Packer can see output
bootloader --append="console=ttyS0,115200n8 console=tty0"

# Install source — Silverblue via ostreecontainer
ostreecontainer --url=quay.io/fedora/fedora-silverblue:42

# Reboot after install
reboot

# Vagrant user
user --name=vagrant --password=vagrant --plaintext --groups=wheel

%post --log=/root/ks-post.log
set -eux

# Vagrant insecure public key for SSH
mkdir -pm 700 /home/vagrant/.ssh
curl -fsSL https://raw.githubusercontent.com/hashicorp/vagrant/main/keys/vagrant.pub \
  > /home/vagrant/.ssh/authorized_keys
chmod 600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh

# Passwordless sudo for vagrant
echo 'vagrant ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/vagrant
chmod 440 /etc/sudoers.d/vagrant

# Ensure sshd is enabled
systemctl enable sshd.service
%end
