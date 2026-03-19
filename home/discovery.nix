{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./dev.nix
  ];

  home = {
    sessionVariables = lib.mkIf pkgs.stdenv.isDarwin {
      SSH_ASKPASS = "/opt/homebrew/bin/ssh-askpass";
      SSH_ASKPASS_REQUIRE = "force";
    };
  };

  programs.git.settings = {
    gpg.format = "ssh";
    user.signingkey = "~/.ssh/yubikey_5c_nano";
    commit.gpgsign = "true";
    credential = {
      helper = "!gh auth git-credential";
      "https://github.com".username = "ananthb";
    };
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "endeavour.local 10.15.16.123 stargazer.local voyager.local" = {
        identityAgent = "none";
        extraOptions = {
          AddKeysToAgent = "no";
          IdentitiesOnly = "yes";
        };
      };
      "*" = {
        identityFile = "~/.ssh/yubikey_5c_nano";
      };
    };
  };

  home.packages = [];
}
