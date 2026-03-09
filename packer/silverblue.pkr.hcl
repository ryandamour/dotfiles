packer {
  required_plugins {
    qemu = {
      version = "~> 1"
      source  = "github.com/hashicorp/qemu"
    }
    vagrant = {
      version = "~> 1"
      source  = "github.com/hashicorp/vagrant"
    }
  }
}

variable "iso_url" {
  type    = string
  default = "https://download.fedoraproject.org/pub/fedora/linux/releases/42/Silverblue/x86_64/iso/Fedora-Silverblue-ostree-x86_64-42-1.1.iso"
}

variable "iso_checksum" {
  type    = string
  default = "file:https://download.fedoraproject.org/pub/fedora/linux/releases/42/Silverblue/x86_64/iso/Fedora-Silverblue-42-1.1-x86_64-CHECKSUM"
}

source "qemu" "silverblue" {
  iso_url      = var.iso_url
  iso_checksum = var.iso_checksum

  vm_name          = "silverblue-42"
  output_directory = "output"
  format           = "qcow2"
  accelerator      = "kvm"
  machine_type     = "q35"

  cpus      = 2
  memory    = 4096
  disk_size = "40G"

  headless = true

  http_directory = "http"

  boot_wait = "5s"
  boot_command = [
    "<up>",
    "e",
    "<down><down><end>",
    " inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/silverblue.ks",
    "<f10>"
  ]

  ssh_username = "vagrant"
  ssh_password = "vagrant"
  ssh_timeout  = "30m"

  qemuargs = [
    ["-serial", "file:serial.log"]
  ]

  shutdown_command = "sudo shutdown -h now"
}

build {
  sources = ["source.qemu.silverblue"]

  # Layer test-time dependencies; rpm-ostree requires a reboot
  provisioner "shell" {
    expect_disconnect = true
    inline = [
      "sudo rpm-ostree install --allow-inactive rsync bats ShellCheck",
      "sudo systemctl reboot"
    ]
  }

  # After reboot: verify packages, clean up, zero free space
  provisioner "shell" {
    pause_before = "30s"
    inline = [
      "rpm -q rsync bats ShellCheck",
      "sudo rpm-ostree cleanup --rollback",
      "sudo dd if=/dev/zero of=/EMPTY bs=1M 2>/dev/null || true",
      "sudo rm -f /EMPTY",
      "sync"
    ]
  }

  post-processor "vagrant" {
    provider_override = "libvirt"
    output            = "silverblue-42.box"
  }
}
