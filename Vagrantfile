# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "silverblue-42"
  config.vm.box_url = "file://#{__dir__}/packer/output/silverblue-42.box"
  config.vm.hostname = "dotfiles-test"

  config.vm.provider :libvirt do |libvirt|
    libvirt.memory = 2048
    libvirt.cpus = 2
  end

  # Sync the dotfiles repo into the VM
  config.vm.synced_folder ".", "/home/vagrant/dotfiles",
    type: "rsync",
    rsync__exclude: [".git/", ".vagrant/", "packer/"]

  # Phase 1: install packages (may exit 100 = reboot required)
  # bats and ShellCheck are pre-baked in the Packer image
  config.vm.provision "install", type: "shell", inline: <<-SHELL
    set -euo pipefail
    cd /home/vagrant/dotfiles
    sudo -u vagrant bash ./install --laptop --ohmyzsh --p10k || exit_code=$?
    exit_code=${exit_code:-0}
    if [ "$exit_code" -eq 100 ]; then
      echo "=== Reboot required for rpm-ostree ==="
      exit 0
    fi
    exit "$exit_code"
  SHELL
end
