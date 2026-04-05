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

  programs = {
    git = {
      signing = {
        format = "ssh";
        key = "~/.ssh/yubikey_5c_nano";
        signByDefault = true;
      };
      settings = {
        credential = {
          helper = "!gh auth git-credential";
          "https://github.com".username = "ananthb";
        };
      };
    };

    ssh = {
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
        "enterprise" = {
          forwardAgent = true;
        };
        "*" = {
          identityFile = "~/.ssh/yubikey_5c_nano";
        };
      };
    };
  };

  home.packages = [];
}
