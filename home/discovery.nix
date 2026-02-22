_: {
  imports = [
    ./dev.nix
  ];

  programs.git.settings = {
    gpg.format = "ssh";
    user.signingkey = "~/.ssh/yubikey_5c_nano";
    commit.gpgsign = "true";
    credential = {
      helper = "!gh auth git-credential";
      "https://github.com".username = "ananthb";
    };
  };

  programs.ssh.extraConfig = ''
    Host *
      IdentityFile ~/.ssh/yubikey_5c_nano
  '';

  home.packages = [ ];
}
