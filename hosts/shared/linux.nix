# Configuration for local (non-garnix) NixOS hosts.
# Imports nixos-common.nix for shared concerns and adds:
# home-manager, tailscale, cftunnel, scripts, user accounts,
# security, boot, SSH, monitoring exporters, etc.
{
  config,
  hostname,
  inputs,
  lib,
  pkgs,
  system,
  username,
  ...
}: let
  tailscaleServeLib = import ../../lib/tailscale-serve-config.nix;
  cftunnelLib = import ../../lib/cftunnel.nix;
in {
  imports = [
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
          imports = let
            hostModule = (import ../../lib/home-host-module.nix {inherit lib;}) hostname;
          in [
            ../../home/common.nix
            hostModule
          ];
        };
        extraSpecialArgs = {
          inherit hostname system username;

          inherit inputs;
        };
      };
    }

    ./nixos-common.nix
    ../../lib/scripts.nix
    (tailscaleServeLib.mkTailscaleServeConfig {inherit hostname;})
    cftunnelLib.mkCftunnel
  ];

  sops = {
    defaultSopsFile = ../../secrets/${hostname}.yaml;
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
  };

  nix.settings.trusted-users = ["root" username];
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

  systemd = {
    sleep.settings.Sleep = {
      AllowSuspend = "no";
      AllowHibernation = "no";
    };

    services = {
      # Protect critical services from oomd
      tailscaled.serviceConfig.ManagedOOMPreference = "none";
    };
  };

  boot.kernel.sysctl = {
    # Auto-reboot on kernel panic after 10 seconds
    "kernel.panic" = 10;
    "kernel.panic_on_oops" = 1;
  };

  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;

  networking = {
    hostName = hostname;
    firewall = {
      # Let Tailscale ACLs govern access on the Tailscale interface.
      trustedInterfaces = [config.services.tailscale.interfaceName];
    };
  };

  users.groups.media.gid = 985;

  users.users.${username} = {
    home = "/home/" + username;
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [
      "wheel"
      "libvirtd"
      "systemd-journal"
    ];
    openssh.authorizedKeys.keys = [
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAINu7u4V6khhhUvepvptel86DN3XMCwZVdQe/7P6WW1KmAAAAFXNzaDphbmFudGhzLXNzaC1rZXktMQ== ananth@yubikey-5c"
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIFCVZPWg3DVxjuORNKJnjaRSPoZ4nYnzM070q0fIeM32AAAAG3NzaDphbmFudGhzLXNzaC1rZXktNWMtbmFubw== ananth@yubikey-5c-nano"
    ];
  };

  security = {
    sudo.enable = false;

    polkit = {
      enable = true;
      extraConfig = ''
        // Allow wheel members to escalate without authentication (replaces sudo NOPASSWD).
        polkit.addRule(function(action, subject) {
          if (subject.isInGroup("wheel")) {
            return polkit.Result.YES;
          }
        });
      '';
    };

    pam = {
      u2f.enable = true;

      services = {
        login.u2fAuth = true;
        sshd.u2fAuth = true;
      };
    };
  };

  environment.shells = [pkgs.fish];

  programs = {
    fish.enable = true;
    mosh.enable = true;
    # SSH known hosts for deploy-rs to SSH between servers
    ssh.knownHosts = {
      endeavour = {
        hostNames = ["endeavour"];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAJxgao1yX2VxxPIozAKlL3cbk2SpBPfxjF29q7S/oFf";
      };
      enterprise = {
        hostNames = ["enterprise"];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFQt03m35by3UEWbU2KiEsr+9jnxXoFwRNflQYKCjE6n";
      };
      stargazer = {
        hostNames = ["stargazer"];
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
    udev.packages = with pkgs; [yubikey-personalization];
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
        disabledCollectors = ["textfile"];
      };

      smartctl.enable = true;
      smartctl.openFirewall = true;
    };
  };

  my-scripts.victoriaMetricsHost = "endeavour";

  environment.systemPackages = with pkgs; [
    e2fsprogs
    ghostty.terminfo
    nixfmt
  ];

  zramSwap.enable = true;

  vault-secrets.vaultAddress = "http://endeavour:8200";
}
