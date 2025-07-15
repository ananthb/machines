{
  config,
  lib,
  pkgs,
  hostname,
  username,
  tsnsrv,
  ...
}@inputs:
{
  imports = [
    ./hardware-configuration.nix
    tsnsrv.nixosModules.default
  ];

  sops.secrets."tsnsrv/auth_key" = { };
  sops.secrets."smtp/username" = {
    owner = config.users.users.grafana.name;
    group = config.users.users.grafana.name;
  };
  sops.secrets."smtp/password" = {
    owner = config.users.users.grafana.name;
    group = config.users.users.grafana.name;
  };
  sops.secrets."smtp/host" = {
    owner = config.users.users.grafana.name;
    group = config.users.users.grafana.name;
  };

  users.groups.media.members = [
    username
    "jellyfin"
    "radarr"
    "sonarr"
    "transmission"
  ];

  systemd.enableEmergencyMode = false;
  systemd.sleep.extraConfig = ''
    AllowSuspend=no
    AllowHibernation=no
  '';

  networking.hostName = hostname;

  # systemd-boot
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.initrd.systemd.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver # previously vaapiIntel
      intel-ocl
      vaapiVdpau
      libvdpau-va-gl
      intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
      vpl-gpu-rt # QSV on 11th gen or newer
    ];
  };

  # System packages
  environment.systemPackages = with pkgs; [
    tpm2-tss
    virt-manager
    spice
    spice-gtk
    spice-protocol
    win-virtio
    win-spice
    pam_rssh
    e2fsprogs

    jellyfin
    jellyfin-web
    jellyfin-ffmpeg
    tsnsrv
  ];

  environment.etc."prometheus/blackbox_exporter.conf".text = ''
    modules:
      icmp:
        prober: icmp
        timeout: 5s
      warp_proxy:
        prober: tcp
        timeout: 5s
        tcp:
          proxy_url: "socks5://localhost:8080"
          target_addr: "https://cloudflare.com"
      http_2xx:
        prober: http
        timeout: 5s
        http:
          method: GET
  '';

  # Set your time zone.
  time.timeZone = "Asia/Kolkata";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_IN";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  programs.fish.enable = true;

  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        swtpm.enable = true;
        ovmf.enable = true;
        ovmf.packages = [ pkgs.OVMFFull.fd ];
      };
    };
    spiceUSBRedirection.enable = true;
  };

  # Modify jellyfin-web index.html for the intro-skipper plugin to work.
  # intro skipper plugin has to be installed from the UI.
  nixpkgs.overlays = [
    (final: prev: {
      jellyfin-web = prev.jellyfin-web.overrideAttrs (
        finalAttrs: previousAttrs: {
          installPhase = ''
            runHook preInstall

            # this is the important line
            sed -i "s#</head>#<script src=\"configurationpage?name=skip-intro-button.js\"></script></head>#" dist/index.html

            mkdir -p $out/share
            cp -a dist $out/share/jellyfin-web

            runHook postInstall
          '';
        }
      );
    })
  ];

  services = import ./services.nix inputs;

  systemd.services.grafana.environment = {
    GF_AUTH_DISABLE_LOGIN_FORM = "true";
    GF_AUTH_BASIC_ENABLED = "false";
    GF_AUTH_PROXY_ENABLED = "true";
    GF_AUTH_PROXY_HEADER_NAME = "X-Tailscale-User-LoginName";
    GF_AUTH_PROXY_HEADER_PROPERTY = "username";
    GF_AUTH_PROXY_AUTO_SIGN_UP = "false";
    GF_AUTH_PROXY_SYNC_TTL = "60";
    GF_AUTH_PROXY_WHITELIST = "::1";
    GF_AUTH_PROXY_HEADERS = "Name:X-Tailscale-User-DisplayName";
    GF_AUTH_PROXY_ENABLE_LOGIN_TOKEN = "true";
  };

  security = {
    pam.rssh.enable = true;
    pam.rssh.settings = {
      auth_key_file = "/etc/ssh/authorized_keys.d/ananth";
      loglevel = "debug";
    };
    pam.services.sudo.rssh = true;
    pam.services.sshd.rssh = true;
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

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
