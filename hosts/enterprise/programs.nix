{ pkgs, username, ... }:
{
  imports = [
    ../../services/logiops.nix
  ];

  # System packages
  environment.systemPackages = with pkgs; [
    ddcutil
    gnome-tweaks
    logitech-udev-rules
    rnnoise-plugin
    tpm2-tss
  ];

  programs = {
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
    };

    virt-manager.enable = true;
  };

  services = {
    displayManager.gdm = {
      enable = true;
    };
    desktopManager.gnome.enable = true;

    devmon.enable = true;

    fwupd.enable = true;

    gvfs = {
      enable = true;
      package = pkgs.gnome.gvfs;
    };

    ollama = {
      enable = true;
      # See https://ollama.com/library
      loadModels = [
        "llama3.2:3b"
        "deepseek-r1:1.5b"
      ];
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;

      extraConfig = {
        pipewire."92-low-latency" = {
          "context.properties" = {
            "default.clock.quantum" = 4096;
            "default.clock.min-quantum" = 2048;
            "default.clock.max-quantum" = 8192;
          };
        };

        pipewire-pulse."92-pulse-latency" = {
          "pulse.properties" = {
            "pulse.min.req" = "4096/48000";
            "pulse.default.req" = "4096/48000";
            "pulse.min.quantum" = "4096/48000";
          };
        };

        pipewire."93-rnnoise" = {
          "context.modules" = [
            {
              name = "libpipewire-module-filter-chain";
              args = {
                "node.description" = "Noise Canceling Microphone";
                "media.name" = "Noise Canceling Microphone";
                "filter.graph" = {
                  nodes = [
                    {
                      type = "ladspa";
                      name = "rnnoise";
                      plugin = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so";
                      label = "noise_suppressor_mono";
                      control = {
                        "VAD Threshold (%)" = 50.0;
                      };
                    }
                  ];
                };
                "capture.props" = {
                  "node.name" = "capture.rnnoise_source";
                  "node.passive" = true;
                };
                "playback.props" = {
                  "node.name" = "rnnoise_source";
                  "media.class" = "Audio/Source";
                };
              };
            }
          ];
        };
      };
    };

    spice-vdagentd.enable = true;
    qemuGuest.enable = true;
    spice-webdavd.enable = true;

    udisks2.enable = true;
  };

  virtualisation = {
    libvirtd = {
      enable = true;
      qemu.swtpm.enable = true;
    };
    podman = {
      enable = true;
      dockerSocket.enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    spiceUSBRedirection.enable = true;
  };

  users.users.${username}.extraGroups = [ "libvirtd" ];

}
