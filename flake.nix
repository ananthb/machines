{
  description = "A SecureBoot-enabled NixOS configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.1";

      # Optional but recommended to limit the size of your system closure.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim/nixos-24.11";
      # If you are not running an unstable channel of nixpkgs,
      # select the corresponding branch of nixvim.
      # url = "github:nix-community/nixvim/nixos-23.05";

      inputs.nixpkgs.follows = "nixpkgs";
    };

    ghostty = {
      url = "github:ghostty-org/ghostty";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      lanzaboote,
      home-manager,
      nixvim,
      ...
    }@inputs:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        system = system;
        config = {
          allowUnfree = true;
        };
      };

    in

    {
      nixosConfigurations = {
        defiant = nixpkgs.lib.nixosSystem {
          inherit system;

          specialArgs = inputs // {
            pkgs = pkgs;
          };

          modules = [
            lanzaboote.nixosModules.lanzaboote
            (
              {
                config,
                pkgs,
                lib,
                ...
              }:
              {
                nix = {
                  settings = {
                    experimental-features = [
                      "nix-command"
                      "flakes"
                    ];
                    auto-optimise-store = true;
                  };
                  gc = {
                    automatic = true;
                    dates = "weekly";
                  };
                };

                # Bootloader & SecureBoot
                boot.initrd.availableKernelModules = [
                  "xhci_pci"
                  "nvme"
                  "usb_storage"
                  "sd_mod"
                ];
                boot.initrd.kernelModules = [ ];
                boot.kernelModules = [ "kvm-intel" ];
                boot.extraModulePackages = [ ];

                boot.initrd.luks.devices = {
                  luksroot = {
                    device = "/dev/disk/by-uuid/08426303-8b48-4547-b1ff-88c52c0b7029";
                    allowDiscards = true;
                    bypassWorkqueues = true;
                  };
                };

                # Lanzaboote currently replaces the systemd-boot module.
                # This setting is usually set to true in configuration.nix
                # generated at installation time. So we force it to false
                # for now.
                boot.loader.systemd-boot.enable = lib.mkForce false;
                boot.initrd.systemd.enable = true;
                boot.loader.efi.canTouchEfiVariables = true;
                boot.loader.efi.efiSysMountPoint = "/efi";
                boot.plymouth.enable = true;

                boot.lanzaboote = {
                  enable = true;
                  pkiBundle = "/etc/secureboot";
                };

                # Filesystems
                fileSystems."/" = {
                  device = "/dev/disk/by-uuid/08426303-8b48-4547-b1ff-88c52c0b7029";
                  fsType = "btrfs";
                  options = [
                    "subvol=@"
                    "compress=zstd"
                  ];
                };

                boot.initrd.luks.devices."nixroot".device =
                  "/dev/disk/by-uuid/2d37d757-cc63-49a8-8f9e-5f61d130a7dc";

                fileSystems."/home" = {
                  device = "/dev/disk/by-uuid/08426303-8b48-4547-b1ff-88c52c0b7029";
                  fsType = "btrfs";
                  options = [
                    "subvol=@home"
                    "compress=zstd"
                  ];
                };

                fileSystems."/nix" = {
                  device = "/dev/disk/by-uuid/08426303-8b48-4547-b1ff-88c52c0b7029";
                  fsType = "btrfs";
                  options = [
                    "subvol=@nix"
                    "compress=zstd"
                  ];
                };

                fileSystems."/var" = {
                  device = "/dev/disk/by-uuid/08426303-8b48-4547-b1ff-88c52c0b7029";
                  fsType = "btrfs";
                  options = [
                    "subvol=@var"
                    "compress=zstd"
                  ];
                };

                fileSystems."/var/swap" = {
                  device = "/dev/disk/by-uuid/08426303-8b48-4547-b1ff-88c52c0b7029";
                  fsType = "btrfs";
                  options = [
                    "subvol=@swap"
                    "compress=zstd"
                  ];
                };

                fileSystems."/efi" = {
                  device = "/dev/disk/by-uuid/075E-D602";
                  fsType = "vfat";
                  options = [
                    "fmask=0022"
                    "dmask=0022"
                  ];
                };

                # Swap
                swapDevices = [ { device = "/var/swap/swapfile"; } ];

                zramSwap.enable = true;

                # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
                # (the default) this is the recommended approach. When using systemd-networkd it's
                # still possible to use this option, but it's recommended to use it in conjunction
                # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
                networking.useDHCP = lib.mkDefault true;
                networking.hostName = "defiant"; # Define your hostname.
                networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.
                networking.networkmanager.connectionConfig."connection.mdns" = 2; # Enable mDNS on all interfaces

                nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
                hardware.cpu.intel.updateMicrocode = true;
                hardware.enableRedistributableFirmware = true;

                # System packages
                environment.systemPackages = [
                  pkgs.nixfmt-rfc-style
                  pkgs.sbctl
                  pkgs.tpm2-tss
                  pkgs.accountsservice
                  pkgs.virt-manager
                  pkgs.virt-viewer
                  pkgs.spice
                  pkgs.spice-gtk
                  pkgs.spice-protocol
                  pkgs.win-virtio
                  pkgs.win-spice
                  pkgs.adwaita-icon-theme
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

                # Define a user account. Don't forget to set a password with ‘passwd’.
                programs.fish.enable = true;
                users.users.ananth = {
                  isNormalUser = true;
                  extraGroups = [
                    "wheel"
                    "libvirtd"
                    "networkmanager"
                    "systemd-journal"
                  ];
                  shell = pkgs.nushell;
                  packages = [ ];
                };

                # Some programs need SUID wrappers, can be configured further or are
                # started in user sessions.
                # programs.mtr.enable = true;
                # programs.gnupg.agent = {
                #   enable = true;
                #   enableSSHSupport = true;
                # };

                # List services that you want to enable:

                # Enable resolved and avahi
                services.resolved.enable = true;
                services.avahi.enable = true;

                # Enable the X11 windowing system.
                services.xserver.enable = true;

                # Enable the GNOME Desktop Environment.
                services.xserver.displayManager.gdm.enable = true;
                services.xserver.desktopManager.gnome.enable = true;

                # Configure keymap in X11
                # services.xserver.xkb.layout = "us";
                # services.xserver.xkb.options = "eurosign:e,caps:escape";

                # Enable CUPS to print documents.
                # services.printing.enable = true;

                # Enable sound.
                hardware.pulseaudio.enable = false;
                services.pipewire = {
                  enable = true;
                  pulse.enable = true;
                };

                # Enable touchpad support (enabled default in most desktopManager).
                services.libinput.enable = true;

                services.prometheus.exporters.node = {
                  enable = true;
                  port = 9100;
                  # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/services/monitoring/prometheus/exporters.nix
                  enabledCollectors = [ "systemd" ];
                  extraFlags = [
                    "--collector.ethtool"
                    "--collector.softirqs"
                    "--collector.tcpstat"
                    "--collector.wifi"
                  ];
                };

                # Enable tailscale
                services.tailscale.enable = true;

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
                services.spice-vdagentd.enable = true;

                services.udev.packages = [ pkgs.moolticute.udev ];

                # Enable the OpenSSH daemon.
                # services.openssh.enable = true;

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
            )

            home-manager.nixosModules.home-manager
            {
              home-manager = {
                extraSpecialArgs = {
                  inherit inputs system;
                };
                useGlobalPkgs = true;
                useUserPackages = true;
                users.ananth = import ./home.nix;
              };
            }
          ];
        };
      };
    };
}
