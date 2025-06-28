# base source
source "vmware-iso" "debian" {
  # communicator = var.communicator
  cpus              = var.cpus
  cores             = var.cores
  disk_size         = var.disk_size
  disk_adapter_type = var.disk_adapter_type
  memory            = var.memory
  shutdown_command  = "echo '${var.ssh_password}' | sudo -E -S poweroff"
  # skip_compaction  = true
  ssh_password = var.ssh_password
  ssh_timeout  = var.ssh_timeout
  ssh_username = var.ssh_username
  version      = var.version
  firmware     = var.firmware
  # headless = var.headless
  network_adapter_type           = "e1000e"
  vmx_remove_ethernet_interfaces = true
  vmx_data = {
    # "cpuid.coresPerSocket"    = "2"
    # "ethernet0.pciSlotNumber" = "32"
    "svga.autodetect"  = true
    "usb_xhci.present" = true
  }
}

# dynamic build all debian os
build {
  name = "debian"
  dynamic "source" {
    for_each = local.debian_builds
    labels   = ["source.vmware-iso.debian"]
    content {
      guest_os_type    = source.value.guest_os_type
      iso_checksum     = source.value.iso_checksum
      iso_url          = source.value.iso_url
      name             = source.value.name
      output_directory = "/Users/gnammyx/VM/${source.value.name}"
      vm_name = source.value.name
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
      "cloud-init clean",
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

  # export Vagrant box
  post-processor "vagrant" {
    output = "${var.box_output_dir}/${source.name}.box"
  }
}