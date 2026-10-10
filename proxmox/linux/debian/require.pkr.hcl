packer {
  required_version = "= 1.16.1"
  required_plugins {
    proxmox = {
      # https://github.com/hashicorp/packer-plugin-proxmox/releases
      version = "= 1.2.4"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}