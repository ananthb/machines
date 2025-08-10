{ ... }:
{
  imports = [
    ./git.nix
    ./nixvim.nix
    ./nushell.nix
    ./tmux.nix
  ];

  programs = {
    home-manager.enable = true;

    nix-index = {
      enable = true;
      enableFishIntegration = true;
    };

    fish.enable = true;

    direnv = {
      enable = true;
      # Nushell needs explicit yes
      enableNushellIntegration = true;
      nix-direnv.enable = true;
    };
  };

}
