{ lib, username, ... }: {

  home.homeDirectory = "/Users/${username}";

  programs.fish.interactiveShellInit = ''
    set fish_greeting ""
    if command -q limactl
      set -gx DOCKER_HOST (limactl list docker --format 'unix://{{.Dir}}/sock/docker.sock')
    end
  '';
}
