{ username, ... }:
{
  home.homeDirectory = "/Users/${username}";

  home.file.".ssh/authorized_keys".source = ../keys/ssh/id_ed25519_sk.pub;

  programs.fish.interactiveShellInit = ''
    set fish_greeting ""
    if command -q limactl
      set -gx DOCKER_HOST (limactl list docker --format 'unix://{{.Dir}}/sock/docker.sock')
    end
  '';

  programs.git.extraConfig = {
    # signing
    gpg.format = "ssh";
    user.signingkey = "~/.ssh/id_ed25519_sk.pub";
    commit.gpgsign = "true";
    credential = {
      helper = "manager";
      "https://github.com".username = "ananthb";
    };
  };
}
