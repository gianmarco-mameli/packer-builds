packer {
  required_version = ">= 1.9.4"
  required_plugins {
    vmware = {
      version = "~> 1"
      source  = "github.com/hashicorp/vmware"
      // https://github.com/hashicorp/packer-plugin-vmware
    }
    vagrant = {
      version = ">= 1.1.5"
      source  = "github.com/hashicorp/vagrant"
      // https://github.com/hashicorp/packer-plugin-vagrant
    }
  }
}