{ pkgs, ... }:
{
  alacritty = import ./alacritty.nix;

  home-manager.enable = true;

  fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting ""
    '';
  };

  git = import ./git.nix;

  nixvim = import ./nixvim.nix;

  nushell = import ./nushell.nix;

  tmux = import ./tmux.nix pkgs;
}
