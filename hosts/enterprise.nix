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
    "google-drive"
    "podman-desktop"
    "seafile-client"
  ];
}
