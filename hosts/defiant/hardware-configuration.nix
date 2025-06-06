{
  lib,
  pkgs,
  hostname,
  ...
}:
{
  # Bootloader & SecureBoot
  boot = {
    initrd.availableKernelModules = [
      "xhci_pci"
      "nvme"
      "usb_storage"
      "sd_mod"
    ];
    initrd.kernelModules = [ ];
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];

    initrd.luks.devices = {
      luksroot = {
        device = "/dev/disk/by-uuid/08426303-8b48-4547-b1ff-88c52c0b7029";
        allowDiscards = true;
        bypassWorkqueues = true;
      };
    };

    # Lanzaboote currently replaces the systemd-boot module.
    # This setting is usually set to true in configuration.nix
    # generated at installation time. So we force it to false
    # for now.
    loader.systemd-boot.enable = lib.mkForce false;
    initrd.systemd.enable = true;
    loader.efi.canTouchEfiVariables = true;
    loader.efi.efiSysMountPoint = "/efi";

    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };

    initrd.luks.devices."nixroot".device = "/dev/disk/by-uuid/2d37d757-cc63-49a8-8f9e-5f61d130a7dc";

    plymouth.enable = true;

    # Enable "Silent Boot"
    consoleLogLevel = 0;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
    ];
    # Hide the OS choice for bootloaders.
    # It's still possible to open the bootloader list by pressing any key
    # It will just not appear on screen unless a key is pressed
    loader.timeout = 0;
  };

  # Filesystems
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/08426303-8b48-4547-b1ff-88c52c0b7029";
    fsType = "btrfs";
    options = [
      "subvol=@"
      "compress=zstd"
    ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/08426303-8b48-4547-b1ff-88c52c0b7029";
    fsType = "btrfs";
    options = [
      "subvol=@home"
      "compress=zstd"
    ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/08426303-8b48-4547-b1ff-88c52c0b7029";
    fsType = "btrfs";
    options = [
      "subvol=@nix"
      "compress=zstd"
    ];
  };

  fileSystems."/var" = {
    device = "/dev/disk/by-uuid/08426303-8b48-4547-b1ff-88c52c0b7029";
    fsType = "btrfs";
    options = [
      "subvol=@var"
      "compress=zstd"
    ];
  };

  fileSystems."/var/swap" = {
    device = "/dev/disk/by-uuid/08426303-8b48-4547-b1ff-88c52c0b7029";
    fsType = "btrfs";
    options = [
      "subvol=@swap"
      "compress=zstd"
    ];
  };

  fileSystems."/efi" = {
    device = "/dev/disk/by-uuid/075E-D602";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  # Swap
  swapDevices = [ { device = "/var/swap/swapfile"; } ];
  zramSwap.enable = true;

  # Host platform
  nixpkgs.hostPlatform = pkgs.system;
  hardware.cpu.intel.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  networking.hostName = hostname; # Define your hostname.
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.
  networking.networkmanager.connectionConfig."connection.mdns" = 2; # Enable mDNS on all interfaces
}
