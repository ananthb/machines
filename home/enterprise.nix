{
  pkgs,
  ...
}:
{
  imports = [
    ../programs/nixvim.nix
    ../programs/nushell.nix
  ];

  home.packages = with pkgs; [
    discord
    element-desktop
    firefox
    gcr
    google-chrome
    ghostty
    gimp
    git-credential-manager
    gnomeExtensions.appindicator
    gnomeExtensions.night-theme-switcher
    gnomeExtensions.gsconnect
    jellyfin-media-player
    junction
    rpi-imager
    slack
    signal-desktop
    telegram-desktop
    vlc
    vscode
    wireshark
    wl-clipboard
    zed-editor
    neovide
  ];

  services.gnome-keyring.enable = true;

  dconf = {
    enable = true;
    settings = {
      "org/gnome/settings-daemon/plugins/power" = {
        sleep-inactive-ac-type = "nothing";
	sleep-inactive-ac-timeout = 0;
      };
      "org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions = with pkgs.gnomeExtensions; [
          appindicator.extensionUuid
          night-theme-switcher.extensionUuid
          gsconnect.extensionUuid
          system-monitor.extensionUuid
        ];
      };
    };
  };

  programs.git.settings = {
    credential = {
      helper = "manager";
      "https://github.com".username = "ananthb";
      credentialStore = "secretservice";
    };
  };

  fonts = {
    fontconfig.enable = true;
  };
}
