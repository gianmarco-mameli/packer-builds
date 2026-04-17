variables {
  apt_cache_url    = ""
  country          = "IT"
  cores            = 1
  cpu_type         = "host"
  disk_size        = "40G"
  disk_type        = "raw"
  domain           = ""
  keyboard         = "us"
  language         = "en"
  locale           = "en_US.UTF-8"
  memory           = 2048
  mirror           = "ftp.it.debian.org"
  ssh_fullname     = "packer"
  ssh_username     = "packer"
  timezone         = "Europe/Rome"
  communicator     = "ssh"
  ssh_timeout      = "60m"
  iso_storage_pool = "local"
  vm_disk_use_swap = false
  vm_disk_device   = "sda"
  vm_disk_partitions = [
    {
      name = "efi"
      size = 1024,
      format = {
        label  = "EFIFS",
        fstype = "fat32",
      },
      mount = {
        path    = "/boot/efi",
        options = "",
      }
    },
    {
      name = "boot"
      size = 1024,
      format = {
        label  = "BOOTFS",
        fstype = "xfs",
      },
      mount = {
        path    = "/boot",
        options = "",
      }
    },
    {
      name = "root"
      size = -1,
      format = {
        label  = "",
        fstype = "xfs",
      },
      mount = {
        path    = "/",
        options = "",
      }
    },
  ]
}
variable "vm_disk_lvm" {
  type = list(object({
    name = string
    partitions = list(object({
      name = string
      size = number
      format = object({
        label  = string
        fstype = string
      })
      mount = object({
        path    = string
        options = string
      })
    }))
  }))
  description = "The LVM configuration for the virtual disk."
  default     = []
}

locals {
  debian = {
    bookworm = {
      vm_id        = 9991
      architecture = "amd64"
      distribution = "bookworm"
      os           = "l26"
      version      = "13.4.0"
      disk_variants = {
        // lvm = "lvm"
        plain = "regular"
      }
    }
  }

  debian_builds = flatten([
    for key, value in local.debian : [
      for d_key, d_value in value.disk_variants : {
        name         = replace("${key}-${value.architecture}-${d_key}-${value.version}", ".", "-")
        distribution = key
        disk_type    = d_value
        # iso_url      = "https://cdimage.debian.org/cdimage/release/${value.version}/${value.architecture}/iso-cd/debian-${value.version}-${value.architecture}-netinst.iso"
        # iso_checksum = "file:https://cdimage.debian.org/cdimage/release/${value.version}/${value.architecture}/iso-cd/SHA512SUMS"
        iso_url      = "https://cdimage.debian.org/cdimage/release/${value.version}/${value.architecture}/iso-cd/debian-${value.version}-${value.architecture}-netinst.iso"
        iso_checksum = "file:https://cdimage.debian.org/cdimage/release/${value.version}/${value.architecture}/iso-cd/SHA512SUMS"
        version      = value.version
        os           = value.os
        vm_id        = value.vm_id
      }
    ]
  ])
}