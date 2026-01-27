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
    statix.enable = true;
    deadnix.enable = true;
  };

  # https://devenv.sh/scripts/
  scripts = {
    deploy.exec = "nix run github:serokell/deploy-rs -- --skip-checks";
    deploy-darwin.exec = "darwin-rebuild switch --flake .#$1";
    deploy-ci.exec = ''
      echo "Deploying endeavour first..."
      nix run github:serokell/deploy-rs -- --skip-checks .#endeavour
      echo "Deploying all hosts..."

    '';
  };

  enterShell = ''
    echo "Welcome to the machines development environment!"
    echo "Available commands: deploy, deploy-darwin, deploy-ci"
  '';
}
