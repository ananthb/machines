{
  config,
  lib,
  pkgs,
  username,
  inputs,
  ...
}:
{
  imports = [
    inputs.NixVirt.nixosModules.default
    inputs.tsnsrv.nixosModules.default

    ../linux.nix
    ./hardware-configuration.nix
    ./vms.nix

    ../../services/collabora-code.nix
    ../../services/immich-ml.nix
    ../../services/media/jellyfin.nix
    ../../services/monitoring/blackbox.nix
    ../../services/monitoring/libvirt.nix
  ];

  # systemd-boot
  boot = {
    loader = {
      systemd-boot.enable = lib.mkForce false;
      efi.canTouchEfiVariables = true;
    };
    initrd.systemd.enable = true;
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };
  };

  # hardware accelerated graphics
  # used by immich and jellyfin
  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver # previously vaapiIntel
      intel-ocl
      libva-vdpau-driver
      libvdpau-va-gl
      intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
      vpl-gpu-rt # QSV on 11th gen or newer
    ];
  };

  # System packages
  environment.systemPackages = with pkgs; [
    gnome-tweaks
    logitech-udev-rules
    solaar
    tpm2-tss
  ];

  # Set your time zone.
  time.timeZone = "Asia/Kolkata";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_IN";

  services = {
    displayManager.gdm = {
      enable = true;
      autoSuspend = false;
    };
    desktopManager.gnome.enable = true;

    fwupd.enable = true;

    ollama = {
      enable = true;
      # See https://ollama.com/library
      loadModels = [
        "llama3.2:3b"
        "deepseek-r1:1.5b"
      ];
    };

    spice-vdagentd.enable = true;
    qemuGuest.enable = true;
    spice-webdavd.enable = true;
  };

  networking.firewall = rec {
    # nfs server
    allowedTCPPorts = [ 2049 ];
    # gsconnect/kdeconnect
    allowedTCPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
    allowedUDPPortRanges = allowedTCPPortRanges;
  };

  # Set default ACL for group-writable files (umask 002)
  systemd = {
    tmpfiles.rules = [
      "A+ /srv/media - - - - default:group::rwx"
    ];

    # TODO: https://github.com/NixOS/nixpkgs/issues/361163#issuecomment-2567342119
    services.gnome-remote-desktop = {
      wantedBy = [ "graphical.target" ];
    };

    # More aggressive than default to prevent GUI lag from memory-heavy workloads
    oomd.settings.OOM = {
      DefaultMemoryPressureDurationSec = "5s";
    };
  };

  virtualisation = {
    libvirtd = {
      enable = true;
      qemu.swtpm.enable = true;
    };
    podman = {
      enable = true;
      dockerSocket.enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    spiceUSBRedirection.enable = true;
  };

  programs.virt-manager.enable = true;

  users.users.${username}.extraGroups = [ "libvirtd" ];

  power.ups = {
    enable = true;
    mode = "netclient";

    users = {
      "nutmon" = {
        passwordFile = config.sops.secrets."nut/users/nutmon".path;
        upsmon = "primary";
      };
    };

    upsmon.monitor."apc1@endeavour" = {
      powerValue = 1;
      user = "nutmon";
    };
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  sops.secrets."nut/users/nutmon".mode = "0444";

  # 32GB swapfile
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 32 * 1024;
    }
  ];

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.11"; # Did you read the comment?
}
