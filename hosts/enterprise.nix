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
    "google-drive"
    "podman-desktop"
    "seafile-client"
  ];
}
