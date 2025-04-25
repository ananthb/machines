{ pkgs, system, ... }:

{
  homebrew.brews = [
    "mas"
    "lima"
    "docker"
    "docker-compose"
    {
      name = "neovim";
      link = false;
    }
  ];
  homebrew.casks = [
    "google-chrome"
    "visual-studio-code"
    "wireshark"
    "discord"
    "slack"
    "slack-cli"
    "vlc"
    "ghostty"
    "1password"
    "neovide"
    "rectangle-pro"
    "yubico-yubikey-manager"
    "raspberry-pi-imager"
    "scroll-reverser"
    "bruno"
    "ddpm"
    "browserosaurus"
  ];
  homebrew.masApps = { "Tailscale" = 1475387142; };
}
