# base source
source "proxmox-iso" "debian" {
  communicator = var.communicator
  cores        = var.cores
  cpu_type     = var.cpu_type
  disks {
    type         = "scsi"
    disk_size    = var.disk_size
    storage_pool = "local-lvm"
    io_thread    = true
    ssd          = true
    discard      = true
    format       = var.disk_type
  }
  efi_config {
    efi_storage_pool  = "local-lvm"
    efi_type          = "4m"
    pre_enrolled_keys = true
  }
  network_adapters {
    model       = "virtio"
    bridge      = "vmbr0"
    mac_address = "aa:bb:cc:dd:ee:ff"
  }

  bios = "ovmf"
  # disable_kvm = true
  memory          = var.memory
  machine         = "q35"
  scsi_controller = "virtio-scsi-single"

  # cloud_init_disk_type = "scsi"
  # shutdown_command = "echo '${var.ssh_password}' | sudo -E -S poweroff"
  # skip_compaction          = true
  ssh_password             = var.ssh_password
  ssh_timeout              = var.ssh_timeout
  ssh_username             = var.ssh_username
  proxmox_url              = var.proxmox_url
  insecure_skip_tls_verify = true
  username                 = var.proxmox_username
  # password                 = var.proxmox_password
  node  = var.proxmox_node
  token = var.proxmox_token
}

# dynamic build all debian os
build {
  name = "debian"
  dynamic "source" {
    for_each = local.debian_builds
    labels   = ["source.proxmox-iso.debian"]
    content {

      boot_iso {
        type              = "scsi"
        iso_url           = source.value.iso_url
        iso_checksum      = source.value.iso_checksum
        iso_storage_pool  = var.iso_storage_pool
        unmount           = true
        keep_cdrom_device = false
        iso_download_pve  = true
      }

      os      = source.value.os
      name    = source.value.name
      vm_name = source.value.name
      vm_id   = source.value.vm_id
      http_content = {
        "/preseed.cfg" = templatefile("${path.root}/http/${source.value.distribution}/preseed.cfg",
          {
            var       = var
            vm_name   = "${source.value.name}"
            disk_type = "${source.value.disk_type}"
            storage = templatefile("${path.root}/http/${source.value.distribution}/storage.pkrtpl.hcl", {
              device     = var.vm_disk_device
              swap       = var.vm_disk_use_swap
              partitions = var.vm_disk_partitions
              lvm        = var.vm_disk_lvm
            })
        })
        "/cloud.cfg" = templatefile("${path.root}/files/cloud-init/cloud.cfg",
          {
            var = var
        })
        "/99-disable-network-config.cfg" = templatefile("${path.root}/files/cloud-init/99-disable-network-config.cfg", {})
      }
      boot_command = [
        "<esc><esc><esc>e<wait>",
        "<down><down><down><end>",
        "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>", /* remove " --- quiet" */
        "auto=true ",
        "lowmem/low=true ",
        "hostname=${source.value.name} ",
        "domain=${var.domain} ",
        "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg ",
        "<wait><f10>"
      ]
    }
  }

  # upgrade packages
  provisioner "shell" {
    execute_command   = "echo '${var.ssh_password}' | {{ .Vars }} sudo -E -S '{{ .Path }}'"
    expect_disconnect = true
    inline = [
      "apt-get update",
      "apt-get -y full-upgrade",
    ]
  }

  # install cloud-init
  provisioner "shell" {
    execute_command = "echo '${var.ssh_password}' | {{ .Vars }} sudo -E -S '{{ .Path }}'"
    inline = [
      "apt-get update",
      "apt-get install -y cloud-init",
      "wget http://${build.PackerHTTPIP}:${build.PackerHTTPPort}/cloud.cfg -O /etc/cloud/cloud.cfg",
      "wget http://${build.PackerHTTPIP}:${build.PackerHTTPPort}/99-disable-network-config.cfg -O /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg"
    ]
  }

  # reboot
  provisioner "shell" {
    execute_command   = "echo '${var.ssh_password}' | {{ .Vars }} sudo -E -S '{{ .Path }}'"
    expect_disconnect = true
    inline = [
      "reboot"
    ]
  }

  # cleanup
  provisioner "shell" {
    execute_command = "echo '${var.ssh_password}' | {{ .Vars }} sudo -E -S '{{ .Path }}'"
    inline = [
      "cloud-init status --wait",
      "cloud-init clean --seed --machine-id --logs",
      ":> /root/.bash_history",
      "apt-get -y autoremove --purge",
      "apt-get autoclean",
      "apt-get clean",
      "echo 'uninitialized' > /etc/machine-id",
      "dd if=/dev/zero of=/EMPTY bs=1M count=100",
      "rm -f /EMPTY",
      "sync"
    ]
  }

}