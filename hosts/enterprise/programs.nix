{ pkgs, username, ... }:
{
  # System packages
  environment.systemPackages = with pkgs; [
    ddcutil
    gnome-tweaks
    logitech-udev-rules
    solaar
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
      autoSuspend = false;
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
      wireplumber.extraConfig.bluetoothEnhancements = {
        "monitor.bluez.properties" = {
          "bluez5.enable-sbc-xq" = true;
          "bluez5.enable-msbc" = true;
          "bluez5.enable-hw-volume" = true;
          "bluez5.roles" = [
            "hsp_hs"
            "hsp_ag"
            "hfp_hf"
            "hfp_ag"
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
