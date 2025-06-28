<!-- markdownlint-disable MD033 -->
<!-- ![Downloads](https://img.shields.io/github/gianmarco-mameli/PackerParallelsBuild/total)  -->

# Packer builds with

![Contributors](https://img.shields.io/github/contributors/gianmarco-mameli/PackerParallelsBuild?style=plastic) ![Forks](https://img.shields.io/github/forks/gianmarco-mameli/PackerParallelsBuild?style=plastic) ![Stargazers](https://img.shields.io/github/stars/gianmarco-mameli/PackerParallelsBuild?style=plastic) ![Issues](https://img.shields.io/github/issues/gianmarco-mameli/PackerParallelsBuild?style=plastic) ![License](https://img.shields.io/github/license/gianmarco-mameli/PackerParallelsBuild?style=plastic)

I created this project to help me build a master Operating System image for my lab, testing and running on various Hypervisors and provisionable with Vagrant or Proxmox
The build runs entirely on Parallels and at the end creates a BOX file deployable with Vagrant

At the moment the config is ready to build a Debian Bookworm image with arm64 architecture, my base lab is a Mac Mini M2 Pro for Fusion, Parallels and Tart, and a Mac Mini 2018 for Proxmox

WARNING: The Tart provider it's in testing

## Requirements

Before start build you need to install Packer; in my case I used the official docs that use Homebrew on MacOS [link](https://developer.hashicorp.com/packer/downloads?product_intent=packer)

You also need your Hypervisor of choice installed and already configured and cd to the directory of choice when the HCL files resides

Next you need to install some plugins, that are included on 'require.pkr.hcl' file.
After cloning the project, this is done changing dir to linux/debian and running the command

```shell
packer init .
```

this will install all plugins included in the file

You also need to create a new HCL file containing all the 'sensitive' variables needed, you can duplicate the file sensitive.pkr.hcl.tmpl to .sensitive.pkr.hcl (if you use this name this is alredy on .gitignore).

Before launch the build I suggest you to check all the files, and tune the config according to your needs, for example you need to modify the variable for the Vagrant box output dir "box_output_dir", in debian.auto.pkr.hcl because it point to my home folder on Macos, in case you need a Vagrant Box
Also maybe you need to modify the timezone, keyboard, language etc., the names of the variables are in most cases descriptive

### Building

From the directory of HCL files launch the validate to verify the build and the files:

```shell
packer validate .
```

If the validate is successfull you can launch the build with:

```shell
packer build .
```

The build starts and you can find the box created in the folder you specified as 'box_output_dir' if end correctly.

After modifications to the files I reccomend to launch the command to format and lint the output files

```shell
packer fmt .
```

## Customization

This project is written keeping in mind my necessities so I reccomend you to check all the passages I implemented before launch.
For example I use a customized preseed file, cloud-init installation and configuration, other tweaks.
Also it's structured to permit multiple dynamic build, with disk variants and os distributions.

## Issues, bugs, requests, collaboration

Feel free to open issues or requests if you find bugs or feature lack

## Next steps

- Multi architecture builds
- Ubuntu images
- Windows images
- Gitlab Pipeline

### Tools and links

- Some of the functions and examples from [Packer Examples for VMware vSphere](https://github.com/vmware-samples/packer-examples-for-vsphere)
- [Hashicorp Packer](https://github.com/hashicorp/packer)
- [Packer Parallels plugin](https://github.com/Parallels/packer-plugin-parallels)
- [Packer Vagrant plugin](https://github.com/hashicorp/packer-plugin-vagrant)
- [Packer Vmware plugin](https://github.com/hashicorp/packer-plugin-vmware)
- [Cloud-Init](https://cloudinit.readthedocs.io/en/latest/)
- [Debian Preseed](https://wiki.debian.org/DebianInstaller/Preseed)

### Support

<a href="https://www.buymeacoffee.com/app/gianmarcomameli"> <img src="https://cdn.simpleicons.org/buymeacoffee" alt="buymeacoffe" height="32" /></a>
<a href="https://ko-fi.com/gianmarcomameli"> <img src="https://cdn.simpleicons.org/kofi" alt="kofi" height="32"/></a>
