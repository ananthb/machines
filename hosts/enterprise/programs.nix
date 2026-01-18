{ pkgs, ... }:
{
  # System packages
  environment.systemPackages = with pkgs; [
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

}
