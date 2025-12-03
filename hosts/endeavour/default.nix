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
    ../../services/arr.nix
    ../../services/immich.nix
    ../../services/jellyfin.nix
    ../../services/open-webui.nix
    ../../services/seafile.nix

    ./cftunnel.nix
    ./hardware-configuration.nix
    ./power.nix
  ];

  users.groups.media.members = [
    username
    "jellyfin"
    "radarr"
    "sonarr"
    "qbittorrent"
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

  services.fwupd.enable = true;

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

  # WARP must be manually set up in proxy mode listening on port 8888.
  # This involves registering a new identity, accepting the tos,
  # setting the mode to proxy, and then setting proxy port to 8888.
  services.cloudflare-warp.enable = true;
  services.cloudflare-warp.openFirewall = false;

  # Jellyfin direct ingress
  services.ddclient =
    let
      getIPv6 = pkgs.writeShellScript ''
        # ------------------------------------------------------------------
        # ddclient custom IPv6 getter
        # Criteria: 
        #   1. Must be Global scope
        #   2. Must start with 2400::/11 (Global Unicast Address Space)
        #   3. Must end with :50 (Static Suffix)
        # ------------------------------------------------------------------

        ip -6 addr show scope global | \
        awk '{
            for(i=1;i<=NF;i++) {
                if($i ~ /^inet6/) {
                    # The next field is the address/cidr
                    addr_field=$(i+1)
                    if (addr_field ~ /^2400:/) {
                        if (addr_field ~ /:50\//) {
                            split(addr_field, a, "/")
                            print a[1]
                            exit 0
                        }
                    }
                }
            }
        }'
      '';
    in
    {
      enable = true;
      passwordFile = config.sops.secrets."cloudflare/token".path;
      protocol = "cloudflare";
      interval = "5min";
      usev6 = "cmd, cmd=${getIPv6}";
      zone = "kedi.dev";
      domains = [
        "tv.kedi.dev"
      ];
    };
  services.caddy.virtualHosts."tv.kedi.dev".extraConfig = ''
    reverse_proxy http://localhost:8096
  '';
  networking.firewall.allowedTCPPorts = [ 443 ];

  systemd.services.qbittorrent.unitConfig.RequiresMountsFor = "/srv";

  # Prometheus Exporters
  services.prometheus.exporters = {
    blackbox = {
      enable = true;
      configFile = pkgs.writeText "blackbox_exporter.conf" ''
        modules:
          https_2xx_via_warp:
            prober: http
            http:
              proxy_url: socks5://localhost:8888
              method: GET
              no_follow_redirects: true
              fail_if_not_ssl: true
      '';

    };

    # TODO: fix this
    mysqld = {
      enable = false;
      runAsLocalSuperUser = true;
      listenAddress = "[::]";
      configFile = pkgs.writeText "config.my-cnf" "";
    };

    postgres.enable = true;
    postgres.runAsLocalSuperUser = true;

    smartctl.enable = true;
  };

  # Caddy webserver
  services.caddy = {
    enable = true;
    globalConfig = ''
      servers {
        trusted_proxies static ::1 127.0.0.0/8 fdc0:6625:5195::0/64 10.15.16.0/24
      }
    '';
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

  sops.secrets = {
    "ddclient/cf_token" = { };
    "nut/users/nutmon".mode = "0444";
  };

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
