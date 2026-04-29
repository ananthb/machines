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
  ...
}: let
  cfg = config.machines;
  tailscaleServeLib = import ../../lib/tailscale-serve-config.nix;
  cftunnelLib = import ../../lib/cftunnel.nix;
in {
  imports = [
    ../../modules/options.nix

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
        users.${cfg.username} = {
          imports = let
            hostModule = (import ../../lib/home-host-module.nix {inherit lib;}) hostname;
          in [
            ../../home/common.nix
            hostModule
          ];
        };
        extraSpecialArgs = {
          inherit hostname system inputs;
          inherit (cfg) username;
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

  nix.settings.trusted-users = ["root" cfg.username];
  nix.gc.dates = "weekly";

  time.timeZone = cfg.timeZone;
  i18n = {
    defaultLocale = cfg.locale;
    # glibc's SUPPORTED has "en_IN UTF-8" but no "en_IN.UTF-8" entry; LANG
    # resolution still finds it via codeset stripping.
    supportedLocales = [
      "C.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
      "en_IN/UTF-8"
    ];
  };

  system.autoUpgrade = {
    enable = true;
    # Fetch latest main from GitHub each run. Using inputs.self.outPath pins the
    # rebuild to an immutable store snapshot taken at build time, so new commits
    # would never land via the timer.
    flake = "github:ananthb/machines";
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

  boot = {
    kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
    kernelParams = ["delayacct"];
    kernel = {
      sysctl = {
        # Auto-reboot on kernel panic after 10 seconds
        "kernel.panic" = 10;
        "kernel.panic_on_oops" = 1;
      };
    };
  };

  networking = {
    hostName = hostname;
    firewall = {
      # Let Tailscale ACLs govern access on the Tailscale interface.
      trustedInterfaces = [config.services.tailscale.interfaceName];
    };
  };

  users.groups.media.gid = 985;

  users.users.${cfg.username} = {
    home = "/home/" + cfg.username;
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [
      "wheel"
      "libvirtd"
      "systemd-journal"
    ];
    openssh.authorizedKeys.keys = cfg.sshKeys;
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
      # Honour client-supplied LANG/LC_* so tmux/mosh see a UTF-8 locale.
      extraConfig = ''
        AcceptEnv LANG LC_*
      '';
    };

    # Yubikey stuff
    udev.packages = [pkgs.yubikey-personalization];
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

  my-scripts.victoriaMetricsHost = lib.mkDefault cfg.monitoring.vmHost;

  environment.systemPackages = [
    pkgs.e2fsprogs
    pkgs.ghostty.terminfo
    pkgs.nixfmt
  ];

  zramSwap.enable = true;

  vault-secrets.vaultAddress = cfg.vault.address;
}
