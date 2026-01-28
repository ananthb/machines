{ pkgs, ... }:

{
  devenv.flakesIntegration = true;

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
    statix.enable = true;
    deadnix.enable = true;
  };

  # https://devenv.sh/scripts/
  scripts = {
    deploy.exec = ''
      if [ "$(uname)" = "Darwin" ]; then
        darwin-rebuild switch --flake .#"$1"
      else
        sudo nixos-rebuild switch --flake .#"$1"
      fi
    '';
    deploy-all.exec = ''nix run github:serokell/deploy-rs "$@"'';
  };

  enterShell = ''
    echo "Welcome to the machines development environment!"
    echo "Available commands: deploy, deploy-all"
  '';
}
