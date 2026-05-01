{inputs, ...}: {
  imports = [
    ./shared/darwin.nix
    inputs.starla.darwinModules.default
  ];

  services.starla.enable = true;

  homebrew = {
    brews = [
      "ssh-askpass"
    ];
    casks = [
      "1password"
      "discord"
      "google-chrome"
      "jellyfin-media-player"
      "ledger-wallet"
      "openmtp"
      "signal"
      "slack-cli"
      "visual-studio-code"
    ];
    masApps = {
      "1Password for Safari" = 1569813296;
      "GarageBand" = 682658836;
      "iMovie" = 408981434;
      "Keynote" = 409183694;
      "Numbers" = 409203825;
      "Pages" = 409201541;
      "Velja" = 1607635845;
      "WhatsApp" = 310633997;
    };
  };
}
