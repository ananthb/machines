{ pkgs, ... }:
{
  home-manager = {
    enable = true;
  };

  fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting ""
    '';
  };

  nushell = import ./nushell.nix;

  alacritty = import ./alacritty.nix;

  git = import ./git.nix;

  nixvim = import ./nixvim.nix;

  tmux = import ./tmux.nix pkgs;
}
