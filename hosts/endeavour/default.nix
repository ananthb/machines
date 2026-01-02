{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../linux
    ./hardware-configuration.nix

    ./6a.nix
    ./cftunnel.nix
    ./power.nix
    ../../services/actual.nix
    ../../services/davis.nix
    ../../services/homepage.nix
    ../../services/media/arr.nix
    ../../services/media/text.nix
    ../../services/monitoring/blackbox.nix
    ../../services/monitoring/grafana.nix
    ../../services/monitoring/postgres.nix
    ../../services/monitoring/probes.nix
    ../../services/monitoring/victoriametrics.nix
    ../../services/open-webui.nix
    ../../services/radicale.nix
    ../../services/vaultwarden.nix
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

  services.fwupd.enable = true;
  services.bcachefs.autoScrub.enable = true;

  # NFS mount from enterprise
  fileSystems."/srv/media" = {
    device = "enterprise.local:/srv/media";
    fsType = "nfs";
    options = [
      "_netdev"
      "auto"
      "nfsvers=4"
    ];
  };

  systemd.services."immich-backup" = {
    # TODO: re-enable after we've trimmed down unnecessary files
    # startAt = "weekly";
    environment.KOPIA_CHECK_FOR_UPDATES = "false";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = "${config.my-scripts.kopia-snapshot-backup} /srv/immich";
    };
  };

  systemd.services."seafile-backup" = {
    # TODO: re-enable after we've trimmed down unnecessary files
    #startAt = "weekly";
    script = ''
      systemctl start seafile-mysql-backup.service
      ${config.my-scripts.kopia-snapshot-backup} /srv/seafile
    '';
    environment.KOPIA_CHECK_FOR_UPDATES = "false";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
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
  system.stateVersion = "24.05"; # Did you read the comment?
}
