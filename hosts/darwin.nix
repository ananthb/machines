{ pkgs, system, username, ... }:

{
  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  services.karabiner-elements.enable = true;

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = system;

  # Add ability to used TouchID for sudo authentication
  security.pam.enableSudoTouchIdAuth = true;

  users.users.${username} = {
    name = username;
    home = "/Users/" + username;
    shell = pkgs.fish;
  };

  environment.shells = [ pkgs.fish ];

  programs.fish.enable = true;

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = [ ];

  fonts.packages = [ pkgs.hack-font ];

  homebrew = {
    enable = true;
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
    onActivation.cleanup = "zap";
    taps = [ "homebrew/cask" ];
    brews = [
      "mas"
      {
        name = "neovim";
        link = false;
      }
    ];
    casks = [
      "google-chrome"
      "visual-studio-code"
      "ghostty"
      "neovide"
      "rectangle-pro"
      "scroll-reverser"
      "ddpm"
      "vlc"
      "logi-options+"
    ];
    masApps = {
      "GarageBand" = 682658836;
      "iMovie" = 408981434;
      "Keynote" = 409183694;
      "Numbers" = 409203825;
      "Pages" = 409201541;
      "Tailscale" = 1475387142;
      "Velja" = 1607635845;
    };
  };
}
