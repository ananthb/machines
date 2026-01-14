{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./dev.nix
  ];

  services.activitywatch.enable = true;

  home.packages = with pkgs; [
    discord
    element-desktop
    firefox
    gcr
    google-chrome
    ghostty
    gimp
    gh
    git-credential-manager
    inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.default
    #inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.desktop
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
    #zed-editor
  ];

  services.gnome-keyring.enable = true;

  programs.gnome-shell = {
    enable = true;
    extensions = with pkgs.gnomeExtensions; [
      { package = appindicator; }
      { package = gsconnect; }
      { package = night-theme-switcher; }
      { package = solaar-extension; }
      { package = system-monitor; }
      { package = tailscale-status; }
      { package = tiling-shell; }
    ];
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
