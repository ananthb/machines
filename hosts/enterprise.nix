{ ... }:

{
  imports = [
    ./darwin.nix
  ];

  homebrew.brews = [ ];
  homebrew.casks = [
    "kopiaui"
  ];
  homebrew.masApps = { };
}
