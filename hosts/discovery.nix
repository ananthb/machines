{ ... }:

{
  imports = [
    ./darwin.nix
  ];

  homebrew.casks = [
    "1password"
    "activitywatch"
    "gimp"
    "ghostty"
    "google-chrome"
    "jellyfin-media-player"
    "ledger-wallet"
    "logi-options+"
    "raspberry-pi-imager"
    "rectangle-pro"
    "scroll-reverser"
    "signal"
    "slack-cli"
    "timemator"
    "visual-studio-code"
    "vlc"
    "yubico-authenticator"
  ];
  homebrew.masApps = {
    "1Password for Safari" = 1569813296;
    "GarageBand" = 682658836;
    "iMovie" = 408981434;
    "Keynote" = 409183694;
    "Numbers" = 409203825;
    "Pages" = 409201541;
    "Velja" = 1607635845;
  };
}
