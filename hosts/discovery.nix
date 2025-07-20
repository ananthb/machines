{ ... }:

{
  homebrew.brews = [
    "lima"
    "docker"
    "docker-compose"
    "magic-wormhole"
    "flyctl"
  ];
  homebrew.casks = [
    "discord"
    "slack"
    "slack-cli"
    "1password"
    "yubico-yubikey-manager"
    "raspberry-pi-imager"
    "bruno"
    "ledger-live"
    "google-drive"
    "utm"
    "zed"
    "jellyfin-media-player"
    "gimp"
  ];
  homebrew.masApps = {
    "1Password for Safari" = 1569813296;
  };
}
