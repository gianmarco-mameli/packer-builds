packer {
  required_version = ">= 1.9.4"
  required_plugins {
    proxmox = {
      version = "~> 1"
      source  = "github.com/hashicorp/proxmox"
      // https://github.com/hashicorp/packer-plugin-proxmox
    }
    vagrant = {
      version = ">= 1.1.5"
      source  = "github.com/hashicorp/vagrant"
      // https://github.com/hashicorp/packer-plugin-vagrant
    }
  }
}