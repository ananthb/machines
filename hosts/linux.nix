{
  hostname,
  inputs,
  pkgs,
  system,
  username,
  ...
}:

{

  imports = [
    inputs.sops-nix.nixosModules.sops
    inputs.quadlet-nix.nixosModules.quadlet
    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.sharedModules = [
        inputs.sops-nix.homeManagerModules.sops
        inputs.nix-index-database.homeModules.nix-index
      ];
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.${username} = {
        imports = [
          ../home/common.nix
          ../home/${hostname}.nix
        ];
      };
      home-manager.extraSpecialArgs = {
        inherit hostname system username;

        inputs = inputs;
      };
    }

    ./common.nix
    ../lib/scripts.nix
  ];

  sops.age.sshKeyPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
  ];

  nix.gc.dates = "weekly";

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = system;

  system.autoUpgrade = {
    enable = true;
    flake = inputs.self.outPath;
    flags = [
      "-L" # print build logs
    ];
    dates = "02:00";
    randomizedDelaySec = "45min";
  };

  systemd.enableEmergencyMode = false;
  systemd.sleep.extraConfig = ''
    AllowSuspend=no
    AllowHibernation=no
  '';

  # Enable systemd-oomd for memory pressure management
  systemd.oomd = {
    enable = true;
    enableRootSlice = true;
    enableUserSlices = true;
    enableSystemSlice = true;
  };

  networking.hostName = hostname;
  networking.firewall.enable = true;
  networking.firewall.allowPing = true;

  users.groups.media.gid = 985;

  users.users.${username} = {
    home = "/home/" + username;
    isNormalUser = true;
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
    sudo.rssh = true;
    sshd.rssh = true;
  };

  security.pam.rssh = {
    enable = true;
    settings = {
      auth_key_file = "/etc/ssh/authorized_keys.d/ananth";
      loglevel = "debug";
    };
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

  services.prometheus.exporters = {
    node = {
      enable = true;
      openFirewall = true;
      # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/services/monitoring/prometheus/exporters.nix
      enabledCollectors = [
        "ethtool"
        "interrupts"
        "perf"
        "processes"
        "systemd"
        "tcpstat"
        "wifi"
      ];
      disabledCollectors = [ "textfile" ];
    };

    smartctl.enable = true;
    smartctl.openFirewall = true;

  };

  environment.systemPackages = with pkgs; [
    e2fsprogs
    ghostty.terminfo
    nixfmt
    pam_rssh
  ];

  zramSwap.enable = true;

  sops.secrets = {
    "email/smtp/host" = { };
    "email/smtp/password" = { };
    "email/smtp/username" = { };
    "gcloud/service_accounts/kopia-hathi-backups.json" = { };
    "kopia/gcs/hathi-backups" = { };
    "nut/users/nutmon" = { };
  };
}
