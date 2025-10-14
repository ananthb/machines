{ ... }:
{
  imports = [
    ./common.nix
  ];

  programs.git.extraConfig = {
    # signing
    gpg.format = "ssh";
    user.signingkey = "~/.ssh/yubikey_5c_nano";
    commit.gpgsign = "true";
    credential = {
      helper = "manager";
      "https://github.com".username = "ananthb";
    };
  };
}
