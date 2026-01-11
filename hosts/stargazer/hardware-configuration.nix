{ pkgs, ... }:
{
  boot = {
    initrd.availableKernelModules = [
      "xhci_pci"
      "usbhid"
      "usb_storage"
      "brcmfmac"
      "brcmutil"
      "v3d"
      "vc4"
    ];
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };

    kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };

    kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
    kernelParams = [ "psi=1" ];
    kernelModules = [ "gpio_fan" ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };

  hardware = {
    raspberry-pi."4" = {
      apply-overlays-dtmerge.enable = true;
      i2c1.enable = true;
      fkms-3d.enable = true;
    };

    deviceTree.enable = true;

    enableAllFirmware = true;

    # Required for the Wireless firmware
    enableRedistributableFirmware = true;

    bluetooth = {
      package = pkgs.bluez;
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
        };
      };
    };
  };
}
