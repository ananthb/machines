{
  lib,
  pkgs,
  system,
  ...
}:
{
  home-manager.enable = true;

  nix-index = {
    enable = true;
    enableFishIntegration = true;
  };

  fish.enable = true;

  git = import ./git.nix {
    inherit lib;
    inherit system;
  };

  gpg = import ./gpg.nix;

  nixvim = import ./nixvim.nix;

  nushell = import ./nushell.nix;

  tmux = import ./tmux.nix pkgs;

  direnv = {
    enable = true;
    # Nushell needs explicit yes
    enableNushellIntegration = true;
    nix-direnv.enable = true;
  };
}
