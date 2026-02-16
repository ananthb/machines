{
  hostname,
  inputs,
  lib,
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
      home-manager = {
        backupFileExtension = "bak";
        sharedModules = [
          inputs.sops-nix.homeManagerModules.sops
          inputs.nix-index-database.homeModules.nix-index
        ];
        useGlobalPkgs = true;
        useUserPackages = true;
        users.${username} = {
          imports =
            let
              hostModule = (import ../lib/home-host-module.nix { inherit lib; }) hostname;
            in
            [
              ../home/common.nix
              hostModule
            ];
        };
        extraSpecialArgs = {
          inherit hostname system username;

          inherit inputs;
        };
      };
    }

    ./common.nix
    ../lib/scripts.nix
  ];

  sops.age.sshKeyPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
  ];

  nix.gc.dates = "weekly";

  # Disable NixOS documentation generation on servers.
  documentation.nixos.enable = lib.mkDefault false;

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

  systemd = {
    enableEmergencyMode = false;
    sleep.extraConfig = ''
      AllowSuspend=no
      AllowHibernation=no
    '';

    # Enable systemd-oomd for memory pressure management
    oomd = {
      enable = true;
      enableRootSlice = true;
      enableUserSlices = true;
      enableSystemSlice = true;
    };

    # Protect critical services from oomd
    services.tailscaled.serviceConfig.ManagedOOMPreference = "none";
  };

  # Journald size limits
  services.journald.extraConfig = ''
    SystemMaxUse=500M
    RuntimeMaxUse=100M
  '';

  boot.kernel.sysctl = {
    # Auto-reboot on kernel panic after 10 seconds
    "kernel.panic" = 10;
    "kernel.panic_on_oops" = 1;
  };

  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;

  networking = {
    hostName = hostname;
    firewall = {
      enable = true;
      allowPing = true;
    };
  };

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

  security = {
    sudo.wheelNeedsPassword = false;

    pam = {
      services = {
        login.u2fAuth = true;
        sudo.u2fAuth = true;
        sudo.rssh = true;
        sshd.rssh = true;
      };

      rssh = {
        enable = true;
        settings = {
          auth_key_file = "/etc/ssh/authorized_keys.d/ananth";
        };
      };
    };
  };

  environment.shells = [ pkgs.fish ];

  programs = {
    fish.enable = true;
    mosh.enable = true;
    # SSH known hosts for deploy-rs to SSH between servers
    ssh.knownHosts = {
      endeavour = {
        hostNames = [ "endeavour" ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAJxgao1yX2VxxPIozAKlL3cbk2SpBPfxjF29q7S/oFf";
      };
      enterprise = {
        hostNames = [ "enterprise" ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFQt03m35by3UEWbU2KiEsr+9jnxXoFwRNflQYKCjE6n";
      };
      stargazer = {
        hostNames = [ "stargazer" ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK1jqNdM9sPcuX9qkMPvlTMnkzyUQY1CnMGYHv2Epogo";
      };
    };
  };

  services = {
    # sched-ext userspace schedulers (amd64 only)
    scx = lib.mkIf (system == "x86_64-linux") {
      enable = true;
      scheduler = "scx_lavd";
    };

    openssh = {
      enable = true;
      settings.PermitRootLogin = "no";
      settings.PasswordAuthentication = false;
    };

    # Yubikey stuff
    udev.packages = with pkgs; [ yubikey-personalization ];
    pcscd.enable = true;

    # Enable resolved and avahi
    resolved.enable = true;
    avahi.enable = true;

    # Enable tailscale
    tailscale.enable = true;

    prometheus.exporters = {
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
