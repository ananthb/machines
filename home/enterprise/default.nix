{
  pkgs,
  ...
}:
{
  imports = [
    ../dev.nix
  ];

  services.activitywatch.enable = true;

  home.packages = with pkgs; [
    discord
    element-desktop
    firefox
    gcr
    ghostty
    gimp
    google-chrome
    jamesdsp
    jellyfin-media-player
    junction
    rpi-imager
    signal-desktop
    slack
    telegram-desktop
    vlc
    vscode
    wireshark
    wl-clipboard
    zed-editor
  ];

  services = {
    gnome-keyring.enable = true;
  };

  programs = {
    gnome-shell = {
      enable = true;
      extensions = with pkgs.gnomeExtensions; [
        { package = another-window-session-manager; }
        { package = appindicator; }
        { package = gsconnect; }
        { package = night-theme-switcher; }
        { package = system-monitor; }
        { package = tailscale-status; }
        { package = tiling-shell; }
      ];
    };

    git.settings = {
      credential = {
        helper = "!/etc/profiles/per-user/ananth/bin/gh auth git-credential";
        "https://github.com".username = "ananthb";
      };
    };

  };

  dconf = {
    enable = true;
    settings = {
      "org/gnome/settings-daemon/plugins/power" = {
        sleep-inactive-ac-type = "nothing";
        sleep-inactive-ac-timeout = 0;
      };
    };
  };

  xdg.desktopEntries.chrome-triton = {
    name = "Chrome (triton.one)";
    exec = "/etc/profiles/per-user/ananth/bin/google-chrome-stable --profile-directory=\"Profile 2\" --class=WorkProfile -- %u";
    terminal = false;
    icon = "google-chrome";
    type = "Application";
    categories = [
      "Network"
      "WebBrowser"
    ];
    mimeType = [ "x-scheme-handler/org-protocol" ];
  };

  fonts = {
    fontconfig.enable = true;
  };

}
