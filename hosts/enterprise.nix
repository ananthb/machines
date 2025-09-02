{ ... }:

{
  imports = [
    ./darwin.nix
  ];

  homebrew.brews = [ ];
  homebrew.casks = [
    "kopiaui"
    "utm"
  ];
  homebrew.masApps = { };
}
