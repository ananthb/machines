{ pkgs, inputs, ... }:
{
  imports = [
    ./dev.nix
  ];

  programs.git.settings = {
    gpg.format = "ssh";
    user.signingkey = "~/.ssh/yubikey_5c_nano";
    commit.gpgsign = "true";
    credential = {
      helper = "manager";
      "https://github.com".username = "ananthb";
    };
  };

  home.packages = [
    pkgs.claude-code
    inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
