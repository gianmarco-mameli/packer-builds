packer {
  required_version = "= 1.15.1"
  required_plugins {
    proxmox = {
      version = "= 1.2.3"
      source  = "github.com/hashicorp/proxmox"
      // https://github.com/hashicorp/packer-plugin-proxmox
      // 1.2.2 cpu_tyoe not working https://github.com/hashicorp/packer-plugin-proxmox/issues/307
    }
  }
}