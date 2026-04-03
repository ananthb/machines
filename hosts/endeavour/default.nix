{
  inputs,
  lib,
  pkgs,
  ipv6Token,
  ...
}: {
  imports = [
    inputs.ht32-panel.nixosModules.default
    inputs.tsnsrv.nixosModules.default

    ../shared/linux.nix
    ./hardware-configuration.nix

    ./6a.nix
    ./power.nix
    ./rclone.nix
    ../../lib/rclone-sync.nix
    ../../services/esphome.nix
    ../../services/mosquitto.nix
    ../../services/immich.nix
    ../../services/media/arr.nix
    ../../services/media/calibre.nix
    ../../services/media/jellyfin.nix
    ../../services/monitoring/ecoflow.nix
    ../../services/monitoring/postgres.nix
    ../../services/monitoring/probes.nix
    ../../services/seafile.nix
    ../../services/timemachinesrv.nix
    ../../services/vault.nix
    ../../services/vaultwarden.nix
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
    vaapiIntel = pkgs.vaapiIntel.override {enableHybridCodec = true;};
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
  environment.systemPackages =
    (with pkgs; [
      tpm2-tss
      unrar
    ])
    ++ [
      pkgs.bcachefs-tools
    ];

  security.tpm2.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Kolkata";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_IN";

  services = {
    # Only publish mDNS on the bond interface to avoid macOS seeing
    # duplicate responses and renaming us to endeavour-2.
    avahi.allowInterfaces = ["bond0"];

    samba.openFirewall = true;
    fwupd.enable = true;
    bcachefs.autoScrub.enable = true;

    vault.tpmUnseal = {
      enable = true;
      handles = [
        "0x81000010"
        "0x81000011"
        "0x81000012"
      ];
    };

    ht32-panel = {
      enable = true;
      web = {
        enable = true;
        listen = "[::]:8686";
      };
    };

    # NFS server - export /srv
    nfs.server = {
      enable = true;
      lockdPort = 4001;
      mountdPort = 4002;
      statdPort = 4000;
      exports = ''
        /srv enterprise(rw,sync,no_subtree_check,crossmnt,no_root_squash)
      '';
    };
  };

  my-services.tailscaleServeConfig = {
    version = "0.0.1";
    services = {
      "svc:esphome" = {
        endpoints = {
          "tcp:443" = "http://localhost:6052";
        };
      };
    };
  };

  my-services.cftunnelConfig = [
    {
      tunnelId = "5fd5fbd5-fc21-4766-b92e-a8b577b4bda5";
      tunnelName = "kedi-apps-1";
      ingress = {
        "6a.kedi.dev" = "http://localhost:8123";
        "calibre.kedi.dev" = "http://localhost:8086";
        "immich.kedi.dev" = "http://localhost:2283";
        "seafile.kedi.dev" = "http://localhost:4444";
        "seerr.kedi.dev" = "http://localhost:5055";
        "vault.kedi.dev" = "http://localhost:8200";
        "vaultwarden.kedi.dev" = "http://localhost:8222";
      };
    }
  ];

  networking.useNetworkd = true;

  systemd = {
    network = {
      netdevs."10-bond0" = {
        netdevConfig = {
          Name = "bond0";
          Kind = "bond";
        };
        bondConfig = {
          Mode = "balance-alb";
          MIIMonitorSec = "1s";
        };
      };
      networks = {
        "20-enp2s0" = {
          matchConfig.Name = "enp2s0";
          networkConfig.Bond = "bond0";
        };
        "20-enp4s0" = {
          matchConfig.Name = "enp4s0";
          networkConfig.Bond = "bond0";
        };
        "25-ethernet" = {
          matchConfig.Name = "en*";
          linkConfig.RequiredForOnline = "no";
          networkConfig = {
            DHCP = "ipv4";
            IPv6AcceptRA = true;
          };
        };
        "30-bond0" = {
          matchConfig.Name = "bond0";
          ipv6AcceptRAConfig.Token = ipv6Token;
          linkConfig.RequiredForOnline = "carrier";
          networkConfig = {
            DHCP = "ipv4";
            IPv6AcceptRA = true;
          };
        };
      };
    };
    services = {
      immich-backup.unitConfig.RequiresMountsFor = "/srv";
      immich-server.unitConfig.RequiresMountsFor = "/srv";
      jellyfin.unitConfig.RequiresMountsFor = "/srv";
      jellyseerr.unitConfig.RequiresMountsFor = "/srv";
      prowlarr.unitConfig.RequiresMountsFor = "/srv";
      qbittorrent.unitConfig.RequiresMountsFor = "/srv";
      radarr.unitConfig.RequiresMountsFor = "/srv";
      sonarr.unitConfig.RequiresMountsFor = "/srv";
    };
  };

  # 16GB swapfile
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 16 * 1024;
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
  system.stateVersion = "24.05"; # Did you read the comment?
}
