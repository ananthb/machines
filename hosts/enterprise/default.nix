{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.NixVirt.nixosModules.default
    inputs.tsnsrv.nixosModules.default

    ../linux.nix
    ./hardware-configuration.nix
    ./programs.nix
    ./vms.nix

    ../../services/coder.nix
    ../../services/immich-ml.nix
    ../../services/monitoring/blackbox.nix
    ../../services/monitoring/libvirt.nix
  ];

  documentation.nixos.enable = true;

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
    kernelModules = [ "i2c-dev" ];
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

  # Set your time zone.
  time.timeZone = "Asia/Kolkata";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_IN";

  security.rtkit.enable = true;

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

  systemd = {
    tmpfiles.rules = [
      # Set default ACL for group-writable files (umask 002)
      "A+ /srv/media - - - - default:group::rwx"
    ];

    # TODO: https://github.com/NixOS/nixpkgs/issues/361163#issuecomment-2567342119
    services.gnome-remote-desktop.wantedBy = [ "graphical.target" ];

    # Desktop-specific oomd tuning (base config in linux.nix)
    oomd.settings.OOM.DefaultMemoryPressureDurationSec = "5s";

    # Protect desktop services from oomd
    services.display-manager.serviceConfig.ManagedOOMPreference = "none";
    user.services = {
      gnome-shell.serviceConfig.ManagedOOMPreference = "none";
      gsd-xsettings.serviceConfig.ManagedOOMPreference = "none";
    };
  };

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
