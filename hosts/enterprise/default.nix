{
  config,
  lib,
  pkgs,
  username,
  ...
}:
{
  imports = [
    ../linux
    ./hardware-configuration.nix

    ./cftunnel.nix
    ../../services/immich.nix
    ../../services/media/dl.nix
    ../../services/media/tv.nix
    ../../services/monitoring/blackbox.nix
    ../../services/monitoring/postgres.nix
    ../../services/seafile.nix
  ];

  # systemd-boot
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.initrd.systemd.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
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
    tpm2-tss
  ];

  # Set your time zone.
  time.timeZone = "Asia/Kolkata";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_IN";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  services.displayManager.gdm.enable = true;
  services.displayManager.gdm.autoSuspend = false;
  services.desktopManager.gnome.enable = true;

  services.fwupd.enable = true;
  services.bcachefs.autoScrub.enable = true;

  # NFS server - export /srv/media
  services.nfs.server = {
    enable = true;
    exports = ''
      /srv/media endeavour.local(rw,sync,no_subtree_check,all_squash,anonuid=65534,anongid=985)
    '';
  };
  networking.firewall.allowedTCPPorts = [ 2049 ];

  # Set default ACL for group-writable files (umask 002)
  systemd.tmpfiles.rules = [
    "A+ /srv/media - - - - default:group::rwx"
  ];

  services.ollama = {
    enable = true;
    # See https://ollama.com/library
    loadModels = [
      "llama3.2:3b"
      "deepseek-r1:1.5b"
    ];
  };

  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.qemu.swtpm.enable = true;

  programs.virt-manager.enable = true;
  services.spice-vdagentd.enable = true;
  services.qemuGuest.enable = true;
  services.spice-webdavd.enable = true;

  users.users.${username}.extraGroups = [ "libvirtd" ];

  # TODO: https://github.com/NixOS/nixpkgs/issues/361163#issuecomment-2567342119
  systemd.services.gnome-remote-desktop = {
    wantedBy = [ "graphical.target" ];
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

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  sops.secrets."nut/users/nutmon".mode = "0444";

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
