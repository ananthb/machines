{ ... }:

{
  imports = [
    ./darwin.nix
  ];

  homebrew.brews = [ ];
  homebrew.casks = [
    "1password"
    "discord"
    "gimp"
    "google-drive"
    "handbrake-app"
    "jordanbaird-ice"
    "ledger-live"
    "raspberry-pi-imager"
    "slack"
    "slack-cli"
    "steam"
    "timemator"
    "visual-studio-code"
  ];
  homebrew.masApps = {
    "1Password for Safari" = 1569813296;
    "Telegram" = 747648890;
  };
}
