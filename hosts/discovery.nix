{ ... }:

{
  homebrew.brews = [
    "docker"
    "docker-compose"
    "magic-wormhole"
    "flyctl"
  ];
  homebrew.casks = [
    "slack"
    "slack-cli"
    "1password"
    "raspberry-pi-imager"
    "ledger-live"
    "gimp"
    "handbrake-app"
  ];
  homebrew.masApps = {
    "1Password for Safari" = 1569813296;
  };
}
