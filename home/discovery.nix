{
  pkgs,
  lib,
  ...
}: let
  askpass = pkgs.stdenv.mkDerivation {
    name = "askpass";
    src = ../lib/askpass.sh;
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/askpass.sh
      chmod +x $out/bin/askpass.sh
    '';
  };
in {
  imports = [
    ./dev.nix
  ];

  home.sessionVariables = lib.mkIf pkgs.stdenv.isDarwin {
    SSH_ASKPASS = "${askpass}/bin/askpass.sh";
    SSH_ASKPASS_REQUIRE = "force";
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
