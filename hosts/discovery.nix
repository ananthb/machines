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
    "ledger-live"
    "signal"
    "slack"
    "slack-cli"
    "steam"
    "timemator"
    "visual-studio-code"
  ];
  homebrew.masApps = {
    "1Password for Safari" = 1569813296;
    "GarageBand" = 682658836;
    "iMovie" = 408981434;
    "Keynote" = 409183694;
    "Numbers" = 409203825;
    "Pages" = 409201541;
    "Telegram" = 747648890;
    "Velja" = 1607635845;
    "WhatsApp" = 310633997;
  };
}
