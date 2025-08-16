{ ... }:

{
  homebrew.brews = [
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
    "raspberry-pi-imager"
    "ledger-live"
    "google-drive"
    "zed"
    "gimp"
    "vlc"
    "handbrake-app"
  ];
  homebrew.masApps = {
    "1Password for Safari" = 1569813296;
  };
}
