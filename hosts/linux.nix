{
  config,
  pkgs,
  system,
  username,
  home-manager,
  bcachefs-tools,
  nixvim,
  sops-nix,
  hostname,
  tsnsrv,
  nix-index-database,
  ...
}:

{

  imports = [

    home-manager.nixosModules.home-manager
    {
      home-manager.sharedModules = [
        sops-nix.homeManagerModules.sops
        nix-index-database.homeModules.nix-index
      ];
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.${username} = {
        imports = [
          ../home/common.nix
          ../home/linux.nix
        ];
      };
      home-manager.extraSpecialArgs = {
        inherit username system nixvim;
      };
    }
    tsnsrv.nixosModules.default

    ./common.nix
  ];

  nixpkgs.overlays = [
    (final: prev: {
      bcachefs-tools = bcachefs-tools.packages.${pkgs.system}.bcachefs-tools;
    })
  ];

  sops.age.sshKeyPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
  ];

  nix.settings.auto-optimise-store = true;
  nix.gc.automatic = true;
  nix.gc.dates = "weekly";

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = system;

  systemd.enableEmergencyMode = false;
  systemd.sleep.extraConfig = ''
    AllowSuspend=no
    AllowHibernation=no
  '';

  networking.hostName = hostname;
  networking.firewall.enable = true;
  networking.firewall.allowPing = true;

  users.users.${username} = {
    name = username;
    home = "/home/" + username;
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [
      "wheel"
      "libvirtd"
      "systemd-journal"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  security.pam.services = {
    login.u2fAuth = true;
    sudo.u2fAuth = true;
  };

  security.pam.rssh = {
    enable = true;
    settings = {
      auth_key_file = "/etc/ssh/authorized_keys.d/ananth";
      loglevel = "debug";
    };
  };
  security.pam.services = {
    sudo.rssh = true;
    sshd.rssh = true;
  };

  environment.shells = [ pkgs.fish ];

  programs.fish.enable = true;
  programs.mosh.enable = true;

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
    settings.PasswordAuthentication = false;
  };

  # Yubikey stuff
  services.udev.packages = with pkgs; [ yubikey-personalization ];
  services.pcscd.enable = true;

  # Enable resolved and avahi
  services.resolved.enable = true;
  services.avahi.enable = true;

  # Enable tailscale
  services.tailscale.enable = true;

  services.tsnsrv = {
    enable = true;
    defaults.authKeyPath = config.sops.secrets."tailscale_api/auth_key".path;
    defaults.urlParts.host = "localhost";
  };

  services.prometheus.exporters = {
    node = {
      enable = true;
      openFirewall = true;
      # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/services/monitoring/prometheus/exporters.nix
      enabledCollectors = [
        "ethtool"
        "perf"
        "systemd"
        "tcpstat"
        "wifi"
      ];
      disabledCollectors = [ "textfile" ];
    };
  };

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    nixfmt-rfc-style
    ghostty.terminfo
    tsnsrv
    pam_rssh
    e2fsprogs
  ];

  zramSwap.enable = true;

  sops.secrets = {
    "email/smtp/host" = { };
    "email/smtp/password" = { };
    "email/smtp/username" = { };
    "gcloud/oauth_self-hosted_clients/id" = { };
    "gcloud/oauth_self-hosted_clients/secret" = { };
    "tailscale_api/auth_key" = { };
    "tailscale_api/tailnet" = { };
  };
}
