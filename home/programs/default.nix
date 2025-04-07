{ lib, pkgs, system, ... }: {
  alacritty = import ./alacritty.nix;

  home-manager.enable = true;

  fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting ""
      set -gx DOCKER_HOST (limactl list docker --format 'unix://{{.Dir}}/sock/docker.sock')
    '';
  };

  git = import ./git.nix {
    inherit lib;
    inherit system;
  };

  nixvim = import ./nixvim.nix;

  nushell = import ./nushell.nix;

  tmux = import ./tmux.nix pkgs;

  direnv = {
    enable = true;
    enableNushellIntegration = true;
    nix-direnv.enable = true;
  };
}
