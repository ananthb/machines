{ ... }:

{
  imports = [
    ./darwin.nix
  ];

  homebrew.brews = [
    "podman"
    "podman-compose"
  ];
  homebrew.casks = [
    "chrome-remote-desktop-host"
    "podman-desktop"
  ];
  homebrew.masApps = { };
}
