# base source
source "parallels-iso" "debian" {
  communicator     = var.communicator
  cpus             = var.cpus
  disk_size        = var.disk_size
  disk_type        = var.disk_type
  memory           = var.memory
  shutdown_command = "echo '${var.ssh_password}' | sudo -E -S poweroff"
  skip_compaction  = true
  ssh_password     = var.ssh_password
  ssh_timeout      = var.ssh_timeout
  ssh_username     = var.ssh_username
}

# dynamic build all debian os
build {
  name = "debian"
  dynamic "source" {
    for_each = local.debian_builds
    labels   = ["source.parallels-iso.debian"]
    content {
      guest_os_type              = source.value.guest_os_type
      iso_checksum               = source.value.iso_checksum
      iso_url                    = source.value.iso_url
      name                       = source.value.name
      output_directory           = "/Users/gnammyx/Parallels/${source.value.name}"
      parallels_tools_flavor     = source.value.parallels_tools_flavor
      parallels_tools_guest_path = "/tmp/prl-tools-{{.Flavor}}.iso"
      parallels_tools_mode       = "upload"
      vm_name                    = source.value.name
      prlctl = [
        ["set", "{{.Name}}", "--3d-accelerate", "off"],
        ["set", "{{.Name}}", "--adaptive-hypervisor", "on"],
        ["set", "{{.Name}}", "--smart-mouse-optimize", "off"],
        ["set", "{{.Name}}", "--keyboard-optimize", "off"],
        ["set", "{{.Name}}", "--sync-host-printers", "off"],
        ["set", "{{.Name}}", "--device-del", "sound0"],
        ["set", "{{.Name}}", "--time-sync", "off"],
      ]
      prlctl_post = [
        ["set", "{{.Name}}", "--device-del", "net0"],
      ]
      http_content = {
        "/preseed.cfg" = templatefile("${path.root}/http/${source.value.distribution}/preseed.cfg",
          {
            var       = var
            vm_name   = "${source.value.name}"
            disk_type = "${source.value.disk_type}"
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

  # install parallels tools
  provisioner "shell" {
    execute_command   = "echo '${var.ssh_password}' | {{ .Vars }} sudo -E -S '{{ .Path }}'"
    expect_disconnect = true
    script            = "${path.root}/files/parallels_tools.sh"
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
      # "userdel ${var.ssh_username}",
      # "rm -rf /etc/sudoers.d/${var.ssh_username}",
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