{ pkgs, system, ... }:

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

  users.users.ananth = {
    name = "ananth";
    home = "/Users/ananth";
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
    onActivation.cleanup = "zap";
    brews = [
      "mas"
      "lima"
      "docker"
    ];
    casks = [
      "google-chrome"
      "visual-studio-code"
      "wireshark"
      "discord"
      "slack"
      "vlc"
      "ghostty"
      "1password"
      "neovide"
    ];
    masApps = { "Tailscale" = 1475387142; };
  };
}
