{
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "nvme"
        "usbhid"
        "usb_storage"
        "uas"
        "sd_mod"
        "sr_mod"
      ];
      kernelModules = [ "bcachefs" ];
    };
    kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
      "net.ipv6.conf.bond0.accept_ra" = 2;
    };
    kernelModules = [ "bcachefs" ];

    initrd.luks.devices."root".device = "/dev/disk/by-uuid/66969cad-e8ba-4a5f-b5e1-a353d09f2384";
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/63de0249-73cc-4608-b228-a9d26f8b110c";
      fsType = "btrfs";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/E445-A150";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
    "/srv" = {
      device = "UUID=f87d0bd3-722c-40b5-b298-9ce396f34003";
      fsType = "bcachefs";
    };
    "/var/lib/immich" = {
      device = "/srv/immich";
      fsType = "bind";
      options = [ "bind" ];
    };
  };

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault false;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware = {
    enableRedistributableFirmware = true;
    cpu.intel.updateMicrocode = true;
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };
}
