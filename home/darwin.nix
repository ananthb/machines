{ ... }:
{
  programs.fish.interactiveShellInit = ''
    set fish_greeting ""
    set -gx DOCKER_HOST (limactl list docker --format 'unix://{{.Dir}}/sock/docker.sock')
  '';
}
