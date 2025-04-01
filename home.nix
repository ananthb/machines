{
  pkgs,
  inputs,
  system,
  username,
  ...
}:
{
  imports = [
    inputs.nixvim.homeManagerModules.nixvim
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.sessionVariables.EDITOR = "nvim";

  home.packages = with pkgs; [
    # Fonts
    hack-font

    # Shell
    nushell
    fish
    mosh
    wl-clipboard

    # Tools
    atool
    tree
    git
    ripgrep
    curl
    httpie
    htop
    delta
    tokei
    fzf
    git-credential-manager
    gcr
    unzip

    # Apps
    firefox
    google-chrome
    alacritty
    inputs.ghostty.packages.${system}.default
    jellyfin-media-player
    wireshark
    moolticute
    neovide
    zed-editor
    bruno
    rpi-imager
    vlc
    slack
    discord
    vscode

    # Gnome extensions
    gnomeExtensions.appindicator
    gnomeExtensions.night-theme-switcher
    gnomeExtensions.gsconnect
  ];

  services.gnome-keyring.enable = true;

  dconf = {
    enable = true;
    settings = {
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

  fonts = {
    fontconfig.enable = true;
  };

  programs = import ./programs pkgs;

  home.stateVersion = "24.05";
}
