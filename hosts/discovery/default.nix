{ pkgs, system, ... }:

{
  homebrew.brews = [ "lima" "docker" "docker-compose" ];
  homebrew.casks = [
    "wireshark"
    "discord"
    "slack"
    "slack-cli"
    "1password"
    "yubico-yubikey-manager"
    "raspberry-pi-imager"
    "bruno"
  ];
  homebrew.masApps = { "1Password for Safari" = 1569813296; };
}
