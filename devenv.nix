{ pkgs, ... }:

{
  # https://devenv.sh/packages/
  packages = [
    pkgs.nixfmt
    pkgs.sops
    pkgs.age
    pkgs.gh
  ];

  # https://devenv.sh/git-hooks/
  git-hooks.hooks = {
    nixfmt.enable = true;
    shellcheck.enable = true;
  };

  # https://devenv.sh/scripts/
  scripts.deploy.exec = "nixos-rebuild switch --flake .#$1";
  scripts.deploy-darwin.exec = "darwin-rebuild switch --flake .#$1";

  enterShell = ''
    echo "Welcome to the machines development environment!"
    echo "Available commands: deploy, deploy-darwin"
  '';
}
