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
    "handbrake-app"
    "jordanbaird-ice"
    "ledger-live"
    "raspberry-pi-imager"
    "slack"
    "slack-cli"
    "steam"
    "tomatobar"
    "visual-studio-code"
  ];
  homebrew.masApps = {
    "1Password for Safari" = 1569813296;
    "Telegram" = 747648890;
  };
}
